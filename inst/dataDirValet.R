dataDirValet <- function(data.dir=NULL){
  conf <- c("(MARFISSCI|MARFIS)","(ISDB|OBSERVER)", "(GROUNDFISH|RV)")
  duplicateDestroyer<-function(data.dir=NULL, conf=NULL){
    cat("Checking for duplicate files..\n")
    allPairs <- data.frame(fileName = character(), filePath = character(), fileAgeM=as.POSIXct(character()), fileSize=integer(), fileKeep = logical(), prefix = character())
    
    for (c in 1:length(conf)){
      namevars = strsplit(gsub(x=conf[c], pattern="[()]", replacement = ""),"\\|")[[1]]
      
      theseO <- list.files(path = data.dir, pattern = paste0("^",conf[c],"\\..*\\.RDATA"), ignore.case = TRUE)
      these <- gsub(x=theseO, pattern = paste0(conf[c],"\\."), replacement = "")
      dups <- these[duplicated(these)]
      if (length(dups)>0){
        for (d in 1:length(dups)){
          thisDup <- paste0(namevars,".",dups[d])
          thisDupP <- file.path(data.dir, thisDup)
          fileInfo <- file.info(thisDupP)
          thisPair <- data.frame(fileName = thisDup, filePath = thisDupP, fileAgeM=fileInfo$mtime, fileSize=fileInfo$size, fileKeep = FALSE, prefix = namevars[1])
          thisPair[thisPair$fileAgeM == max(thisPair$fileAgeM),"fileKeep"] <- "TRUE"
          allPairs <- rbind(allPairs,thisPair)
        }
      }
    }
    if (nrow(allPairs)>0){
      deleters = allPairs[allPairs$fileKeep==F,"filePath"]
      if(nrow(allPairs)/length(deleters)!=2){
        cat("Halting - there is an unexpected number of files flagged for deletion\n")
        print(allPairs)
        stop()
      }else{
        # delete old dups
        sapply(deleters, file.remove)
        cat("These files were deleted.  They were duplicates of files for which you had multiple copies with different prefixes (e.g. MARFIS/MARFISSCI)):\n")
        cat(paste("\t",deleters, collapse='\n'))
        cat("\n")
      }
    } else{
      cat("No duplicates found\n")
    }
  }
  prefixFixer <-  function(data.dir=NULL, conf = NULL){
    cat('Checking for prefix variants (e.g. "RV." vs "GROUNDFISH.", "MARFIS." vs "MARFISSCI.", etc)\n')
    allRenamed =data.frame(filePath = character(), newPath=character())
    for (c in 1:length(conf)){
      #desired name is written first
      namevars = strsplit(gsub(x=conf[c], pattern="[()]", replacement = ""),"\\|")[[1]]
      theseOld <- list.files(path = data.dir, pattern = paste0("^",namevars[-1],"\\..*\\.RDATA"), ignore.case = TRUE)
      theseTmp <- gsub(pattern = paste0("^",namevars[-1],"\\."),replacement = "", theseOld)
      theseNew <- gsub(pattern = paste0("^",namevars[-1],"\\..*\\.RDATA"), namevars[1], x= theseOld)
      
      theseBad <- file.path(data.dir,theseOld)
      theseNew <- gsub(pattern = paste0(namevars[-1],"\\."),  paste0(namevars[1],"\\."), x= theseBad)
      
      renamers = data.frame(filePath = theseBad, newPath = theseNew)
      renamers$newPath <-gsub("//","/",renamers$newPath)
      renamers$filePath <-gsub("//","/",renamers$filePath)
      for (r in 1:nrow(renamers)){
        file.rename(renamers[r,"filePath"], renamers[r,"newPath"])
      }
      allRenamed <- rbind(allRenamed, renamers)
    }
    if (nrow(allRenamed)>0){
      cat("These files were renamed to use a common prefix (e.g. MARFIS/MARFISSCI)):\n")
      print(allRenamed)
    }else{
      cat("No prefix variants found\n")
    }
  }
  
  duplicateDestroyer(data.dir = data.dir, conf=conf)
  prefixFixer(data.dir = data.dir, conf=conf)
  data_tweaks2(db = "ALL", data.dir = data.dir)
}




