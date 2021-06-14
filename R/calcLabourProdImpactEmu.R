#' @title calcLabourProdImpactEmu
#' @description Spatial and temporal aggregation of labour productivity impacts from climate change emulated by the LAMACLIMA project based on method of Orlov (see Orlov et al. 2019. Economic Losses of Heat-Induced Reductions in Outdoor Worker Productivity: a Case Study of Europe. Economics of Disasters and Climate Change, 3(3), 191-211.)
#' @param timestep 5-year or yearly
#' @param cellular cellular is true
#' @return List of magpie object of gridded (0.5) productivity as share of 1 (full productivity)
#' @author Michael Windisch
#' @importFrom magclass dimSums

calcLabourProdImpactEmu <- function(timestep="5year",cellular=TRUE){
  
  out <- readSource("LabourImpactEmu",convert=FALSE)
  
  if(timestep == "5year"){
    out <- out[,seq(1995,2095,5),]
  } else if(timestep == "yearly"){
    out <- out
  }
  
  
  crop_area_weight <- dimSums(calcOutput("Croparea", sectoral="kcr", physical=TRUE, irrigation=FALSE,
                                         cellular=TRUE, cells=cells, aggregate = FALSE, years="y1995", round=6), dim=3)

  
  return(list(
    x=out,
    weight=crop_area_weight,
    unit="Percentage of total labour productivity",
    description="Labour productivity impacts as percentage of full labour prod 1",
    isocountries=FALSE))
  
}



