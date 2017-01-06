# Several schemas of compression

# keep only _n_ Least Significant Bits - the baseline approach
lsb <- function(x, n){ bitwAnd(x, bitwShiftL(1L,n)-1) }

# keep [n:m] bits - don't care for little things, capture the grand picture
msb <- function(x, n, m){ bitwAnd(bitwShiftR(x,m), bitwShiftL(1L,n+1-m)-1) }

# saturate - once overflow, stick to the max
sat <- function(x, n){ if(x < bitwShiftL(1L,n)-1) x else bitwShiftL(1L,n)-1 }

address <- function(x){}
