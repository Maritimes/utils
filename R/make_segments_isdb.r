#' @title make_segments_isdb
#' @description This function takes a df of the isdb data (including fields
#' \code{FISHSET_ID} and LAT1:LAT4 and LONG1:LONG4) and makes a 
#' spatialLinesDataFrame which can be plotted.If selected, it can also QC them.
#' Each line will have the following columns in the resulting data frame:
##' \itemize{
##'  \item \code{FISHSET_ID} This uniquely identifies a set
##'  \item \code{QCPOS} This field identifies potential issues with the line - 
##'  including NA positions, positions that are "0", incorrect hemisphere, or 
##'  impossible coordinates
##'  \item \code{QCTIME} This field identifies potential issues with the timing 
##'  of the vertices making up the line.  For example,  P2 should occur after 
##'  P1, and 2 vertices cannot occur simultaneously.  Sets less than 5 min or 
##'  greater than 24 hr are also noted
##'  \item \code{LEN_KM} This field shows the calculated distance of the 
##'  resultant line in kms
##'  \item \code{N_VALID_VERT} This field shows how many vertices appear 
##'  correct after NAs, 0s and othe problematic values have been dropped
##' }
#' @param isdb.df This is the dataframe you want to plot.  isdb dataframes are
#' characterized by the existence of the following fields:
##' \itemize{
##'  \item \code{FISHSET_ID}
##'  \item \code{LAT1} and \code{LONG1}
##'  \item \code{LAT2} and \code{LONG2}
##'  \item \code{LAT3} and \code{LONG3}
##'  \item \code{LAT4} and \code{LONG4}
##' }
##' @param do.qc default is \code{FALSE}
##' @param return.choice This determines what the function returns.  The default
##' value of \code{"lines"} returns a SpatialLinesDataFrame, where the dataframe 
##' contains the generated QC information.  Any other value for 
##' \code{return.choice} will instead return of data frame of all of the 
##' FISHSET_IDs, the QC determination of each line, the length of each line (in 
##' km), and the number of valid vertices. 
##' The QC data checks the positions of each FISHSET for NAs, Zeroes, or 
##' otherwise data.  Additionally, if the line has a length of zero, that is 
##' noted as well.
#' @param createShp default is \code{TRUE}. This determines whether or not 
#' shapefiles will be generated in your working directory.
#' @author  Mike McMahon, \email{Mike.McMahon@@dfo-mpo.gc.ca}
#' @export
make_segments_isdb <- function(isdb.df, do.qc = FALSE, return.choice = "lines", createShp=TRUE){
 
  # Pull out coordinates, stack em, create and populate QC status field ----
  crs.geo <- sp::CRS(SRS_string="EPSG:4326") 
  dup=length(isdb.df[duplicated(isdb.df), "FISHSET_ID"])
  
  if (dup>0){
    isdb.df <- isdb.df[!duplicated(isdb.df), ]
    cat(paste("\n",dup," duplicate rows were removed from your data"))
  }
  rownames(isdb.df) <- isdb.df$FISHSET_ID

  p1=cbind(isdb.df[c("FISHSET_ID","LAT1","LONG1", "DATE_TIME1")],"1")
  colnames(p1)<-c("FISHSET_ID", "LAT", "LONG", "DATETIME","P")
  p2=cbind(isdb.df[c("FISHSET_ID","LAT2","LONG2", "DATE_TIME2")],"2")
  colnames(p2)<-c("FISHSET_ID", "LAT", "LONG", "DATETIME","P")
  p3=cbind(isdb.df[c("FISHSET_ID","LAT3","LONG3", "DATE_TIME3")],"3")
  colnames(p3)<-c("FISHSET_ID", "LAT", "LONG", "DATETIME","P")
  p4=cbind(isdb.df[c("FISHSET_ID","LAT4","LONG4", "DATE_TIME4")],"4")
  colnames(p4)<-c("FISHSET_ID", "LAT", "LONG", "DATETIME","P")
  isdbPos <- rbind(p1,p2,p3,p4)
  rm(p1)
  rm(p2)
  rm(p3)
  rm(p4)
  isdbPos <- isdbPos[order(isdbPos$FISHSET_ID, isdbPos$P),]

  if (do.qc) {
    isdbPos$QC <- ""
    isdbPos$QCTIME <- ""
    fishsetsBadPt <- NA
    fishsetsBadTime <- NA
    #datechecks
    #year 9999 is a default date - change to NA
    isdbPos[which(lubridate::year(isdbPos$DATETIME) == 9999),"DATETIME"]<-NA
    #earliest date is 1977
    validYear<-c(1977:lubridate::year(Sys.Date()))

    if (length(unique(isdbPos[!(lubridate::year(isdbPos$DATETIME) %in% validYear) & !is.na(isdbPos$DATETIME),"FISHSET_ID"]))>0){
      isdbPos[!(lubridate::year(isdbPos$DATETIME) %in% validYear) & !is.na(isdbPos$DATETIME),"QCTIME"]<- 'Invalid year'
      fishsetsBadTime = c(fishsetsBadTime, unique(isdbPos[!(lubridate::year(isdbPos$DATETIME) %in% validYear) & !is.na(isdbPos$DATETIME),"FISHSET_ID"]))
    }
    #more date analysis after bad pos recs have been dropped 
  }

  #Just drop NAs - they're really common, and evident from nVertices
  posNA = length(isdbPos[is.na(isdbPos$LAT) | is.na(isdbPos$LONG),])
  if (posNA>0) isdbPos[is.na(isdbPos$LAT) | is.na(isdbPos$LONG),"LONG"] <- NA

  #Following are flagged conditions - capture for QC
  posBad = length(isdbPos[which(isdbPos$LONG<=-180 | isdbPos$LONG>=180 | 
                             isdbPos$LAT > 90 | isdbPos$LAT < -90 |
                             isdbPos$LONG>0 & isdbPos$LONG < 180 |
                             isdbPos$LAT == 0 | isdbPos$LONG==0),"LONG"])
  if (posBad>0){
    if (do.qc) {
      if (length(isdbPos[which(isdbPos$LONG<= -180 | isdbPos$LONG>= 180 | 
                            isdbPos$LAT>90 | isdbPos$LAT< -90),"LONG"])>0){
        isdbPos[which(isdbPos$LONG<= -180 | isdbPos$LONG>=180 | 
                       isdbPos$LAT>90 | isdbPos$LAT< -90),"QC"] <- 'pos:impossible'
        fishsetsBadPt = c(fishsetsBadPt, unique(isdbPos[which(isdbPos$LONG<= -180 | isdbPos$LONG>=180 | 
                                                               isdbPos$LAT>90 | isdbPos$LAT< -90),"FISHSET_ID"]))
      }
      #coordinates of 0 are almost certainly wrong (for ISDB) - these will be dropped
      if (length(isdbPos[which(isdbPos$LAT == 0 | isdbPos$LONG==0),"LONG"])>0){
        isdbPos[which(isdbPos$LAT == 0 | isdbPos$LONG==0),"QC"] <- 'pos:0'
        fishsetsBadPt = c(fishsetsBadPt, unique(isdbPos[which(isdbPos$LAT == 0 | isdbPos$LONG==0),"FISHSET_ID"]))
      }
      #wrong hemisphere? not necessarily incorrect
      posHem = length(isdbPos[which(isdbPos$LONG>0 & isdbPos$LONG < 180),"LONG"] )
      if (posHem>0){
        isdbPos[which(isdbPos$LONG>0 & isdbPos$LONG < 180),"QC"] <- 'pos:HEMISPHERE'
        cat(paste0("\n",posHem," coords seem to be in the wrong hemisphere, but will be plotted as-is"))
      }
    }
    #Flag posBad for drop (except wrong hemisphere)
    isdbPos[which(isdbPos$LONG<= -180 | isdbPos$LONG>=180 | 
                 isdbPos$LAT>90 | isdbPos$LAT< -90 |
                 isdbPos$LAT == 0 | isdbPos$LONG==0) ,"LONG"] <- NA
  }

  # Do the removal (drop all records which contain an NA -----------------------
  isdbPos <- isdbPos[stats::complete.cases(isdbPos),] 
 
  if (do.qc){
    isdbTim <- isdbPos[,c("FISHSET_ID","DATETIME", "P","QCTIME")] 
    isdbTim.qc <- unique(isdbTim[,c("FISHSET_ID","QCTIME")])
    for (k in 1:length(isdbTim.qc[,"FISHSET_ID"])){
      this = isdbTim[isdbTim$FISHSET_ID==isdbTim.qc[k,"FISHSET_ID"],]
      this = this[order(this$P),]
        for (j in 1:nrow(this)-1){
          if (nrow(this)<2) next
          d = as.numeric(difftime(this$DATETIME[nrow(this)], this$DATETIME[nrow(this)-1]), units = "hours")
          if (d < 0) {
            isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]<-paste(c("Negative Time",isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]), collapse = ", ")
            fishsetsBadTime = c(fishsetsBadTime, isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"FISHSET_ID"])
            } else if (d == 0) {
              isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]<-paste(c("No Time between pts",isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]), collapse = ", ")
              fishsetsBadTime = c(fishsetsBadTime, isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"FISHSET_ID"])
            }else if (d > 48) {
            isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]<-paste(c("Time between pts > 48hr",isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]), collapse = ", ")
          }else if (d < 0.008) {
            isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]<-paste(c("Time between pts < 5min",isdbTim.qc[isdbTim.qc$FISHSET_ID==this$FISHSET_ID[1],"QCTIME"]), collapse = ", ")
          }
          this = this[-nrow(this),] 
        }
    }
  }
 
  all.sets.lines<-list()
  
  if (do.qc){
    # Roll up all the comments for each set into one col ----------------------
    isdb.qc <- stats::aggregate(QC ~ FISHSET_ID, isdbPos, function(x) paste0(unique(x), collapse = ", "))
    rownames(isdb.qc) <-isdb.qc$FISHET_ID
    isdb.qc$LEN_KM<-NA
    isdb.qc$N_VALID_VERT<-NA
    #this makes lines, but captures QC data too
    for (i in 1:length(unique(isdbPos$FISHSET_ID))){
      this.a <-unique(isdbPos$FISHSET_ID)[i]
      if (length(unique(isdbPos[isdbPos$FISHSET_ID==this.a,][3:2][,1]))==1 &
          length(unique(isdbPos[isdbPos$FISHSET_ID==this.a,][3:2][,2]))==1){
        #these have same start and end coords
        isdb.qc[isdb.qc$FISHSET_ID==this.a,"LEN_KM"]<-0
        fishsetsBadPt = c(fishsetsBadPt, isdb.qc[isdb.qc$FISHSET_ID==this.a,"FISHSET_ID"])
        isdb.qc[isdb.qc$FISHSET_ID==this.a,"QC"]<-paste(c(isdb.qc[isdb.qc$FISHSET_ID==this.a,"QC"], 'Zero_Len Line'), collapse = ", ")
        all.sets.lines[[i]]<-NULL
        next
      }else{
        li = sp::Line(isdbPos[isdbPos$FISHSET_ID==this.a,][3:2])
        all.sets.lines[[i]]<-sp::Lines(li,ID=this.a)
      }
      this.len = sp::LinesLength(Ls = all.sets.lines[[i]], longlat = TRUE)
      isdb.qc[isdb.qc$FISHSET_ID==this.a,"N_VALID_VERT"]<-length(all.sets.lines[[i]]@Lines[[1]]@coords)/2
      isdb.qc[isdb.qc$FISHSET_ID==this.a,"LEN_KM"]<-this.len
    }
    fishsetsBadPt = unique(fishsetsBadPt)
  }else{
    #this just  makes lines
    for (i in 1:length(unique(isdbPos$FISHSET_ID))){
      this.a <-unique(isdbPos$FISHSET_ID)[i]
      if (length(unique(isdbPos[isdbPos$FISHSET_ID==this.a,][3:2][,1]))==1 & 
          length(unique(isdbPos[isdbPos$FISHSET_ID==this.a,][3:2][,2]))==1){
        #these have same start and end coords
        all.sets.lines[[i]]<-NULL
        next
      }else{
        li = sp::Line(isdbPos[isdbPos$FISHSET_ID==this.a,][3:2])
        all.sets.lines[[i]]<-sp::Lines(li,ID=this.a)
      }
      this.len = sp::LinesLength(Ls = all.sets.lines[[i]], longlat = TRUE)
    }
  }
  if(length(all.sets.lines)>0){
  #drop any lines that have zero length
  all.sets.lines = all.sets.lines[!sapply(all.sets.lines, is.null)]
  all.sets.lines = sp::SpatialLines(all.sets.lines)
  sp::proj4string(all.sets.lines) <- crs.geo
  }
  cat(paste0("\n",length(all.sets.lines), " of ", nrow(isdb.df), " sets could be made into lines having at least 2 points."))
  
  if (do.qc){
    #Sort the qc field prior to merging into line df
    isdb.qc = merge(isdbTim.qc, isdb.qc, all.x=TRUE)
    colnames(isdb.qc)[colnames(isdb.qc)=="QC"]<-"QCPOS"
    for (k in 1:nrow(isdb.qc)){
      isdb.qc$QCPOS[k] <- paste(sort(unlist(strsplit(isdb.qc$QCPOS[k], ", ")),decreasing = TRUE), collapse = ", ")
      isdb.qc$QCTIME[k] <- paste(sort(unlist(strsplit(isdb.qc$QCTIME[k], ", ")),decreasing = TRUE), collapse = ", ")
      
    }
    #clean up fields
    isdb.qc$QCTIME<-sub(",$","",trimws(isdb.qc$QCTIME))
    isdb.qc$QCPOS<-sub(",$","",trimws(isdb.qc$QCPOS))

    if(length(all.sets.lines)>0){
    all.sets.lines<-sp::SpatialLinesDataFrame(all.sets.lines, isdb.qc, match.ID = "FISHSET_ID")
    fishsetsBadPt = setdiff(fishsetsBadPt, all.sets.lines@data$FISHSET_ID)
    }
    if (any(!is.na(fishsetsBadPt))){
      fishsetsBadPt <- fishsetsBadPt[!is.na(fishsetsBadPt)]
      cat(paste0("\n","The following ",length(fishsetsBadPt)," sets are unplottable, due to either insufficient valid coordinate pairs or zero-length lines:"))
      for (j in 1:length(fishsetsBadPt)){
        cat(paste0("\n\t ",fishsetsBadPt[j],": ",isdb.qc[which(isdb.qc$FISHSET_ID == fishsetsBadPt[j]),"QCPOS"]))
      }
    }
    if  (any(!is.na(fishsetsBadTime))){
      fishsetsBadTime <- fishsetsBadTime[!is.na(fishsetsBadTime)]
      cat(paste0("\n","The following ",length(fishsetsBadTime)," sets reported invalid dates/times, due to identical values across positions, or time-order mismatch:"))
      for (l in 1:length(fishsetsBadTime)){
        cat(paste0("\n\t ",fishsetsBadTime[l],": ",isdb.qc[which(isdb.qc$FISHSET_ID == fishsetsBadTime[l]),"QCTIME"]))
      }
    }
  }else{
    cat("\n","For more info on the lines that failed or other issues, run this with function with 'do.qc=TRUE'")
    if(length(all.sets.lines)>0){
      all.sets.lines<-sp::SpatialLinesDataFrame(all.sets.lines, isdb.df[1], match.ID = "FISHSET_ID")
    }
  }
  #add original attribs to line
  if(length(all.sets.lines)>0){
    all.sets.lines@data= merge(all.sets.lines@data, isdb.df)
  }
  
  if (createShp) {
    all.sets.lines = Mar.utils::prepare_shape_fields( all.sets.lines)
    rgdal::writeOGR(obj =  all.sets.lines, layer =paste0("isdb_lines"), dsn=getwd(), driver="ESRI Shapefile", overwrite_layer=TRUE)
    cat(paste0("\nA shapefile ('isdb_lines') was written to  ",getwd(),": "))
  }
  
  
  if (return.choice != "lines" & do.qc){
    return(isdb.qc)
  }else{
    if(length(all.sets.lines)>0){
    return(all.sets.lines)
    }else{
      return(NULL)
    }
  }
}
