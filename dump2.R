mb <- read.csv(file="tuple_PART.csv",header=T,sep=',')
sPART_0 <- with( subset(mb,track_nTracks>0),
                 data.frame(ptEMTF   = track_pt.0.,
                            ptEMTF_i = track_pt_int.0.,
                            eta      = track_eta.0.,
                            eta_i    = track_eta_int.0.,
                            theta    = track_theta.0.,
                            theta_i  = track_theta_int.0.,
                            phi      = track_phi.0.,
                            phi_i    = track_phi_int.0.,
                            phi1     = track_hit_phi_int.0.,
                            phi2     = track_hit_phi_int.1.,
                            phi3     = track_hit_phi_int.2.,
                            phi4     = track_hit_phi_int.3.,
                            theta1   = track_hit_theta_int.0.,
                            theta2   = track_hit_theta_int.1.,
                            theta3   = track_hit_theta_int.2.,
                            theta4   = track_hit_theta_int.3.,
                            clct1    = track_hit_pattern.0.,
                            clct2    = track_hit_pattern.1.,
                            clct3    = track_hit_pattern.2.,
                            clct4    = track_hit_pattern.3.,
                            fr1      = track_hit_FR.0.,
                            fr2      = track_hit_FR.1.,
                            fr3      = track_hit_FR.2.,
                            fr4      = track_hit_FR.3.
                 )
               )

save(file="sPART_0.RData",sPART_0)
