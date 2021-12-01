
# ==========================================================================
#  
#  Title: 1_create_adj.R
#  Author: Mridul Joshi
#  Date: 10/8/2020			
#  Description: Produces dyadic data and adjacency matrices
# ===========================================================================*/


#################### Clear out everything ##################

rm(list = ls())


################# Setup and load packages ###############


setwd("C:/Users/Mridul Joshi/Google Drive/APE_M2/Semester2/MachineLearning/HW3")

list.of.packages    <- c("tidyverse", "readstata13", "data.table", "igraph" )
new.packages        <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org")
invisible(lapply(list.of.packages, library, character.only = TRUE))


# Import edge list
edges <- read.csv("C:/Users/Mridul Joshi/Google Drive/Dissertation/4_Data/1_friendship.csv") %>%
        select(c("aid", "friend_id")) %>%
        distinct()
  
######################## UNDIRECTED GRAPH MATRIX ##############################


g1 <- graph.data.frame(edges, directed=F)

g_dir <- graph.data.frame(edges, directed=T)

comp <- components(g1)
comp_memb <- as.data.frame(comp$membership)

small_sub <- names(which(table(comp$membership) < 4 ))
rm_nodes <- as.vector(V(g1)[which(comp$membership %in% small_sub)])

g2 <- delete_vertices(g1, rm_nodes)

# undirected adjacency matrix
write.csv(as.data.frame(components(g2)$membership), "C:/Users/Mridul Joshi/Google Drive/Dissertation/4_Data/compmem.csv")


adj <- as_adjacency_matrix(g2)

adj_mat <- as.data.frame(as.matrix(adj))

write.csv(adj_mat, "C:/Users/Mridul Joshi/Google Drive/Dissertation/4_Data/adj.csv")


############################## DYADIC DATA ##################################

adj_mat$aid <- rownames(adj_mat)

dyad_reg <- gather(adj_mat, fr_id, link, -aid)

sort_dyad_reg <- dyad_reg[!duplicated(t(apply(dyad_reg[c("aid", "fr_id")], 1, sort))), ] %>%
                 filter(aid != fr_id)
            
write.csv(sort_dyad_reg, "C:/Users/Mridul Joshi/Google Drive/Dissertation/4_Data/dyad_reg_data.csv")


################################ RANDOMLY ASSIGNED PEERS ##################################


#set seed 
set.seed(32418)

peers <- dyad_reg %>% 
         select(fr_id) %>%
         rename(fr_id_rand = fr_id) %>%
         mutate(rand = runif(length(fr_id_rand))) %>%
         arrange(rand) %>%
         select(fr_id_rand) %>%
         cbind(dyad_reg) %>%
         mutate(link=replace(link, aid==fr_id_rand, 0)) %>%
         subset(link>=1) %>%
         select(c("aid", "fr_id_rand"))
  

# creade adjacency matrix for randomly assigned peers
g1_rand <- graph.data.frame(peers, directed=F)

adj_rand <- as_adjacency_matrix(g1_rand)

adj_mat_rand <- as.data.frame(as.matrix(adj_rand))

write.csv(adj_mat_rand, "C:/Users/Mridul Joshi/Google Drive/Dissertation/4_Data/adj_rand.csv")


################################# DIRECTED GRAPH MATRIX ##################################

g_dir <- graph.data.frame(edges, directed=T)

comp <- components(g_dir)
comp_memb <- as.data.frame(comp$membership)

# remove components smaller than 4
small_sub <- names(which(table(comp$membership) < 4 ))
rm_nodes <- as.vector(V(g_dir)[which(comp$membership %in% small_sub)])

g2_dir <- delete_vertices(g_dir, rm_nodes)


# final set of network components
write.csv(as.data.frame(components(g2)$membership), "C:/Users/Mridul Joshi/Google Drive/Dissertation/4_Data/compmem.csv")


# final directed adjacency matrix
adj_dir <- as_adjacency_matrix(g2_dir)
adj_mat_dir <- as.data.frame(as.matrix(adj))

write.csv(adj_mat_dir, "C:/Users/Mridul Joshi/Google Drive/Dissertation/4_Data/adj_dir.csv")



