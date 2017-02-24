#include <vector>
#include <sstream>
#include <string>
#include <string.h>
#include <algorithm>
#include <iostream>
#include <map>
#include <list>
#include <fstream>
#include "TFile.h"
#include "TTree.h"
#include "TBranch.h"
#include "TLeaf.h"
using namespace std;

//.L root2csv2.C++
//root2csv("muon{nMuons/I:pt[2]/F:eta[2]/F:theta[2]/F:phi[2]/F:charge[2]/I}:hit{nHits/I:eta[24]/F:theta[24]/F:phi[24]/F:phi_loc[24]/F:eta_int[24]/I:theta_int[24]/I:phi_int[24]/I:endcap[24]/I:sector[24]/I:sector_index[24]/I:station[24]/I:ring[24]/I:CSC_ID[24]/I:chamber[24]/I:FR[24]/I:pattern[24]/I:roll[24]/I:subsector[24]/I:isRPC[24]/I:vetoed[24]/I:BX[24]}:track{nTracks/I:pt[4]/F:eta[4]/F:theta[4]/F:phi[4]/F:phi_loc[4]/F:pt_int[4]/I:eta_int[4]/I:theta_int[4]/I:phi_int[4]/I:BX[4]/I:endcap[4]/I:sector[4]/I:sector_index[4]/I:mode[4]/I:charge[4]/I:nHits[4]/I:nRPC[4]/I:hit_eta[16]/F:hit_theta[16]/F:hit_phi[16]/F:hit_phi_loc[16]/F:hit_eta_int[16]/I:hit_theta_int[16]/I:hit_phi_int[16]/I:hit_endcap[16]/I:hit_sector[16]/I:hit_sector_index[16]/I:hit_station[16]/I:hit_ring[16]/I:hit_CSC_ID[16]/I:hit_chamber[16]/I:hit_FR[16]/I:hit_pattern[16]/I:hit_roll[16]/I:hit_subsector[16]/I:hit_isRPC[16]/I:hit_vetoed[16]/I:BX[16]/I}")

list<string> parse(const char *leaflist, map< string, pair<char,size_t> > &leafs, map< string, pair<void*,size_t> > &memmap, char *buffer, string prefix = ""){
    int byteshift = 0;
    const char *defaultType = "F";
    list<string> ordering;

    char *copy = strdup(leaflist);
    for(char *item=strtok(copy,":"); item != NULL; item = strtok(NULL,":")){
        char *type;
        if( (type = strrchr(item,'/')) != NULL ) *type++ = '\0';
        else type = const_cast<char*>(defaultType);
        if( *type != 'I' && *type != 'i' && *type != 'F' && *type != 'f' ){
            cout << "Invalid type: " << *type << " accept only 4-byte types to avoid dealing with padding" << endl;
            exit(0);
        }
        size_t nElements = 1;
        char *bra = strchr(item,'['), *ket = strchr(item,']');
        if( bra != NULL && ket != NULL && ket > bra ){
            *ket = '\0';
            nElements = atoi(bra+1);
            *bra = '\0';
        }
        //cout << item << " : " << byteshift << endl;
        leafs [prefix+item] = pair<char,size_t>(*type,nElements);
        memmap[prefix+item] = pair<void*,size_t>((void*)(buffer + byteshift), 4*nElements);
        ordering.push_back(prefix+item);
        byteshift += 4*nElements;
    }
    free(copy);
    return ordering;
}

void root2csv(const char *leaflist, bool addEntryNumbers=true, const char *file="tuple_1.root"){
    if( strlen(leaflist) == 0 ) return;

    TFile *f = new TFile(file);
    TDirectoryFile *df = (TDirectoryFile*)f->Get("ntuple");
    TTree *t = (TTree*)df->Get("tree");

    list<string> sequence;
    list<string> simpleBranches;
    map<string,string> complexBranches;
    string acc;
    char *copy = strdup(leaflist), *saveptr;
    for(const char *item=strtok_r(copy,":",&saveptr); item != NULL; item = strtok_r(NULL,":",&saveptr)){
        if( strchr(item,'{') != NULL && strchr(item,'}') == NULL ){
            acc = item;
            continue;
        }
        else if( strchr(item,'{') == NULL && strchr(item,'}') != NULL ){
            acc += ":";
            acc += item;
            size_t bra = acc.find("{"), ket = acc.find("}");
            if( bra == string::npos || ket == string::npos ){
                cout << "Broken branch description: " << acc << endl;
                return;
            }
            complexBranches[ acc.substr(0,bra) ] = acc.substr(bra+1,ket-bra-1);
            sequence.push_back(acc.substr(0,bra));
            acc.clear();
            continue;
        }
        else if( acc.length() ){
            acc += ":";
            acc += item;
        } else {
            simpleBranches.push_back(item);
            sequence.push_back(item);
        }
    }

    list<string> ordering;
    map< string, char*> buffers;
    map< string, pair<char,size_t> > leafs;
    map< string, pair<void*,size_t> > memmap;

    for(list<string>::const_iterator br=sequence.begin(); br!=sequence.end(); br++){
        map<string,string>::const_iterator branch = complexBranches.find(*br);
        if( branch == complexBranches.end() ) continue; // we don't care about simple branches in this version yet
        TBranch *b = (TBranch*)t->GetBranch(branch->first.c_str());
        buffers[branch->first] = new char[16384];
        b->SetAddress(buffers[branch->first]);
        list<string> tmp = parse(branch->second.c_str(), leafs, memmap, buffers[branch->first],branch->first+"_");
        ordering.insert(ordering.end(),tmp.begin(),tmp.end());
    }

    string csvFileName(file);
    size_t ext = csvFileName.rfind(".root");
    size_t pre = csvFileName.rfind("/");
    if( ext != string::npos ) csvFileName = csvFileName.substr(0,ext);
    if( pre != string::npos ) csvFileName = csvFileName.substr(pre+1);
    csvFileName.append(".csv");
    ofstream csvFile(csvFileName.c_str());

    if( addEntryNumbers ) csvFile<<"EntryNumber,";

    for(list<string>::const_iterator l = ordering.begin(); l != ordering.end(); l++){
        map< string, pair<char,size_t> >::const_iterator observable = leafs.find(*l);
        if( observable == leafs.end() ){
            cout << "Corrupted list of leafs" << endl;
            return;
        }
        const string &name  = observable->first;
        const char   &type  = observable->second.first;
        const size_t &nElem = observable->second.second;
        if( nElem > 1 ){
            stringstream elements;
            for(size_t i=0; i<nElem; i++){
                elements<<name<<"["; 
                elements<<i<<"]";
                if( l != --ordering.end() || i+1 != nElem ) elements<<",";
                else elements<<endl;
            }
            csvFile<<elements.str();
        } else {
            csvFile<<name;
            if( l != --ordering.end() ) csvFile<<",";
            else csvFile<<endl;
        }
    }

    for(int event=0; event>-1; event++){

        for(map<string,char*>::const_iterator buff = buffers.begin(); buff != buffers.end(); buff++)
            bzero( buff->second, 16384 );

        if( !t->GetEvent(event) ) break;

        if( addEntryNumbers ) csvFile << event << ",";

        for(list<string>::const_iterator l = ordering.begin(); l != ordering.end(); l++){
            map< string, pair<char,size_t> >::const_iterator observable = leafs.find(*l);
            if( observable == leafs.end() ){
                cout << "Corrupted list of leafs" << endl;
                return;
            }
            const string &name  = observable->first;
            const char   &type  = observable->second.first;
            const size_t &nElem = observable->second.second;
            for(size_t item=0; item<nElem; item++){
                switch( type ){
                    case 'I' : { int    *array = (int*)   memmap[name].first; csvFile<<array[item]; } break;
                    case 'F' : { float  *array = (float*) memmap[name].first; csvFile<<array[item]; } break;
                    case 'D' : { double *array = (double*)memmap[name].first; csvFile<<array[item]; } break;
                    default  : break;
                }
                if( l != --ordering.end() || item+1 != nElem ) csvFile<<',';
            }
        }
        csvFile<<endl;
    }

    csvFile.close();
}
