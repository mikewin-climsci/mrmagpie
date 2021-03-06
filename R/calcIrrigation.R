#' @title calcIrrigation
#' @description This function extracts irrigation water (airrig: water applied additionally to rainfall) from LPJmL to MAgPIE
#'
#' @param selectyears years to be returned
#' @param version Switch between LPJmL4 and LPJmL5
#' @param climatetype Switch between different climate scenarios (default: "CRU_4")
#' @param time Time smoothing: average, spline or raw (default)
#' @param averaging_range only specify if time=="average": number of time steps to average
#' @param dof             only specify if time=="spline": degrees of freedom needed for spline
#' @param harmonize_baseline FALSE (default): no harmonization, TRUE: if a baseline is specified here data is harmonized to that baseline (from ref_year on)
#' @param ref_year Reference year for harmonization baseline (just specify when harmonize_baseline=TRUE)
#' @param rainfedweight For clustering airrig is weighted with cropland_irrigated + rainfedweight * cropland_rainfed (default: 0.01)
#'
#' @return magpie object in cellular resolution
#' @author Felicitas Beier, Abhijeet Mishra
#'
#' @examples
#' \dontrun{ calcOutput("Irrigation", aggregate = FALSE) }
#'
#' @importFrom magpiesets findset
#' @importFrom mrcommons toolHarmonize2Baseline

calcIrrigation <- function(selectyears="all",
                           version="LPJmL5", climatetype="CRU_4", time="spline", averaging_range=NULL, dof=4,
                           harmonize_baseline=FALSE, ref_year=NULL, rainfedweight=0.01){

  sizelimit <- getOption("magclass_sizeLimit")
  options(magclass_sizeLimit=1e+10)
  on.exit(options(magclass_sizeLimit=sizelimit))

  if(harmonize_baseline==FALSE){

    if(time=="raw"){
      # Read in airrig (irrigation water applied additionally to rainfall where irrigation takes place):
      lpj_airrig   <- collapseNames(calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="irrig", aggregate=FALSE,
                                                                 harmonize_baseline=FALSE,
                                                                 time="raw")[,,"irrigated"])

      # Load LPJmL to MAgPIE mapping to aggregate to MAgPIE crops
      LPJ2MAG      <- toolGetMapping("MAgPIE_LPJmL.csv", type = "sectoral", where = "mappingfolder")

      # Aggregate to MAgPIE crops
      mag_airrig   <- toolAggregate(lpj_airrig, LPJ2MAG, from = "LPJmL", to = "MAgPIE", dim=3.1, partrel=TRUE)
      # Remove pasture (pasture is not irrigated in MAgPIE)
      mag_airrig   <- mag_airrig[,,"pasture",invert=T]

      # Remove negative airrig
      mag_airrig[mag_airrig<0] <- 0

    } else {
      # Time smoothing:
      x     <- calcOutput("Irrigation", version=version, climatetype=climatetype, aggregate=FALSE,
                          harmonize_baseline=FALSE, time="raw")

      # Smoothing data through average:
      if(time=="average"){
        mag_airrig <- toolTimeAverage(x, averaging_range=averaging_range)

      # Smoothing data with spline method:
      } else if(time=="spline"){
        mag_airrig <- toolTimeSpline(x, dof=dof)
        # Replace value in 2100 with value from 2099 (LPJmL output ends in 2099)
        if ("y2099" %in% getYears(mag_airrig)) {
          mag_airrig <- toolFillYears(mag_airrig, c(getYears(mag_airrig, as.integer=TRUE)[1]:2100))
        }
      } else if(time!="raw"){
        stop("Time argument not supported!")
      }
    }

  } else {
    # Harmonization
    if(time=="raw"){
      stop("Harmonization with raw data not possible. Select time='spline' when applying harmonize_baseline=TRUE")
    } else {
      # Load smoothed data
      baseline   <- calcOutput("Irrigation", version=version, climatetype=harmonize_baseline, aggregate=FALSE,
                             harmonize_baseline=FALSE, time=time, dof=dof, averaging_range=averaging_range)
      x          <- calcOutput("Irrigation", version=version, climatetype=climatetype, aggregate=FALSE,
                             harmonize_baseline=FALSE, time=time, dof=dof, averaging_range=averaging_range)
      # Harmonize to baseline
      mag_airrig <- toolHarmonize2Baseline(x=x, base=baseline, ref_year=ref_year, limited=TRUE, hard_cut=FALSE)
    }
  }

  if(selectyears!="all"){
    years       <- sort(findset(selectyears,noset="original"))
    mag_airrig  <- mag_airrig[,years,]
  }

  # Check for NAs
  if(any(is.na(mag_airrig))){
    stop("produced NA airrig")
  }

  # Clustering weight:
  cropland_total   <- dimSums(calcOutput("Croparea", sectoral="kcr", physical=TRUE, cellular=TRUE, irrigation=TRUE, aggregate = FALSE, years="y1995", round=6), dim=3.2)
  crop_area_weight <- collapseNames(cropland_total[,,"irrigated"]) + rainfedweight * collapseNames(cropland_total[,,"rainfed"])

  return(list(
    x=mag_airrig,
    weight=crop_area_weight,
    unit="m^3 per ha per yr",
    description="Irrigation water (water applied in addition to rainfall) for different crop types following LPJmL irrigation system assumptions",
    isocountries=FALSE))
}
