get_all_parents <- function(aphia_id, taxa_data) {
  # Initialize a vector to store parent_ids
  parent_ids <- c()
  
  # Iterate until reaching the root node (parent_id = NA)
  while (!is.na(aphia_id)) {
    # Find the parent_id of the current aphia_id
    parent_id <- taxa_data$parent_id[taxa_data$aphia_id == aphia_id]
    
    # Append the parent_id to the vector
    parent_ids <- c(parent_ids, parent_id)
    
    # Update aphia_id to the parent_id for the next iteration
    aphia_id <- parent_id
  }
  
  # Return the vector of parent_ids
  return(parent_ids[!is.na(parent_ids)])
}