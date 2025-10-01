
library(celestial)

celestial_coordmatch<-
function (coordref, coordcompare, rad = 2, inunitref = "deg", 
    inunitcompare = "deg", radunit = "asec", sep = ":", kstart = 10, 
    ignoreexact = FALSE, ignoreinternal = FALSE, matchextra = FALSE, 
    smallapprox = FALSE) 
{
    if (inunitref %in% c("deg", "rad", "sex") == FALSE) {
        stop("inunitref must be one of deg, rad or sex")
    }
    if (inunitcompare %in% c("deg", "rad", "sex") == FALSE) {
        stop("inunitcompare must be one of deg, rad or sex")
    }
    if (radunit %in% c("deg", "amin", "asec", "rad") == FALSE) {
        stop("radunit must be one of deg, amin, asec or rad")
    }
    origrad = rad
    coordref = rbind(coordref)
    if (missing(coordcompare)) {
        coordcompare = coordref
        if (missing(ignoreinternal)) {
            ignoreinternal = TRUE
        }
    }
    coordcompare = rbind(coordcompare)
    N = length(coordref[, 1])
    kmax = length(coordcompare[, 1])
    if (length(rad) == 1) {
        rad = rep(rad, N)
    }
    if (length(rad) != N) {
        stop("Length of rad must either be 1 or the same length as rows in coordref")
    }
    if (inunitref == "sex") {
        coordref[, 1] = hms2deg(coordref[, 1], sep = sep)
        coordref[, 2] = dms2deg(coordref[, 2], sep = sep)
        coordref = cbind(as.numeric(coordref[, 1]), as.numeric(coordref[, 
            2]))
    }
    if (inunitref == "rad") {
        coordref[, 1] = coordref[, 1] * 180/pi
        coordref[, 2] = coordref[, 2] * 180/pi
    }
    if (inunitcompare == "sex") {
        coordcompare[, 1] = hms2deg(coordcompare[, 1], sep = sep)
        coordcompare[, 2] = dms2deg(coordcompare[, 2], sep = sep)
        coordcompare = cbind(as.numeric(coordcompare[, 1]), as.numeric(coordcompare[, 
            2]))
    }
    if (inunitcompare == "rad") {
        coordcompare[, 1] = coordcompare[, 1] * 180/pi
        coordcompare[, 2] = coordcompare[, 2] * 180/pi
    }
    if (radunit == "asec") {
        radmult = (pi/180)/3600
    }
    if (radunit == "amin") {
        radmult = (pi/180)/60
    }
    if (radunit == "deg") {
        radmult = (pi/180)
    }
    rad = rad * radmult
    userad = max(rad, na.rm = TRUE)
    coordrefxyz = sph2car(coordref[, 1:2, drop = FALSE], deg = TRUE)
    coordcomparexyz = sph2car(coordcompare[, 1:2, drop = FALSE], 
        deg = TRUE)
    if (matchextra & dim(coordref)[2] > 2 & dim(coordcompare)[2] > 
        2) {
        if (dim(coordref)[2] == dim(coordcompare)[2]) {
            coordrefxyz = cbind(coordrefxyz, coordref[, 3:dim(coordref)[2], 
                drop = FALSE] * radmult)
            coordcomparexyz = cbind(coordcomparexyz, coordcompare[, 
                3:dim(coordcompare)[2], drop = FALSE] * radmult)
        }
    }
    ksuggest = min(kstart, dim(coordcomparexyz)[1])
    while (is.na(ksuggest) == FALSE) {
        tempmatch = nn2(coordcomparexyz, coordrefxyz, searchtype = "radius", 
            radius = userad, k = ksuggest)
        ignore = tempmatch[[1]] == 0
        tempmatch[[2]][ignore] = NA
        if (smallapprox == FALSE) {
            tempmatch[[2]] = 2 * asin(tempmatch[[2]]/2)
        }
        if (ignoreinternal) {
            remove = which(tempmatch[[1]] - 1:length(coordcomparexyz[, 
                1]) == 0)
            tempmatch[[1]][remove] = 0
            tempmatch[[2]][remove] = NA
        }
        if (ignoreexact) {
            remove = which(!(tempmatch[[2]] <= rad & tempmatch[[2]] > 
                0))
            tempmatch[[1]][remove] = 0
            tempmatch[[2]][remove] = NA
        }
        else {
            remove = which(!tempmatch[[2]] <= rad)
            tempmatch[[1]][remove] = 0
            tempmatch[[2]][remove] = NA
        }
        if (all(is.na(tempmatch[[2]][, ksuggest]))) {
            kendmin = NA
        }
        else {
            kendmin = min(tempmatch[[2]][, ksuggest], na.rm = TRUE)
        }
        if (is.na(kendmin) == FALSE & ksuggest < kmax) {
            comp = tempmatch[[2]][, ksuggest]
            print(str(comp))
            if (any(comp>0,na.rm=T)) {
              ksuggest = ceiling(ksuggest * max(rad[comp > 0]/comp[comp > 
                  0], na.rm = TRUE))
              ksuggest = min(ksuggest, kmax)
            } else { 
              ksuggest = NA
            }
        }
        else {
            ksuggest = NA
        }
    }
    keepcols = which(colSums(is.na(tempmatch[[2]])) < N)
    tempmatch[[1]] = matrix(tempmatch[[1]][, keepcols], nrow = N, 
        byrow = FALSE)
    tempmatch[[2]] = matrix(tempmatch[[2]][, keepcols], nrow = N, 
        byrow = FALSE)
    if (radunit == "asec") {
        tempmatch[[2]] = tempmatch[[2]]/((pi/180)/3600)
    }
    if (radunit == "amin") {
        tempmatch[[2]] = tempmatch[[2]]/((pi/180)/60)
    }
    if (radunit == "deg") {
        tempmatch[[2]] = tempmatch[[2]]/((pi/180))
    }
    if (length(tempmatch[[1]]) > 0) {
        Nmatch = rowSums(tempmatch[[1]] != 0)
    }
    else {
        Nmatch = NA
    }
    if (is.na(Nmatch[1]) == FALSE) {
        bestID = tempmatch[[1]][, 1]
        bestsep = tempmatch[[2]][, 1]
        select = which(bestID > 0)
        bestsep = bestsep[select]
        bestID = bestID[select]
        orderID = order(bestsep)
        keep = !duplicated(bestID[orderID])
        bestrefID = select[orderID][keep]
        bestcompareID = bestID[orderID][keep]
        bestsep = bestsep[orderID][keep]
        reorderID = order(bestrefID)
        bestrefID = bestrefID[reorderID]
        bestcompareID = bestcompareID[reorderID]
        bestsep = bestsep[reorderID]
        bestmatch = data.frame(refID = bestrefID, compareID = bestcompareID, 
            sep = bestsep)
        output = list(ID = tempmatch[[1]], sep = tempmatch[[2]], 
            Nmatch = Nmatch, bestmatch = bestmatch)
    }
    else {
        output = list(ID = tempmatch[[1]], sep = tempmatch[[2]], 
            Nmatch = Nmatch, bestmatch = NA)
    }
    return(output)
}

library(argparser)

parser = arg_parser(
    description="Assign label from training catalogue to target catalogue using nearest-neighbour match in feature space."
)
parser<-add_argument(parser,
    short="-i", "--input", 
    help="path to the target file",
)
parser<-add_argument(parser,
    short="-o", "--output",
    help="path to the output with added label",
)
parser<-add_argument(parser,
    short="-t", "--train", 
    help="path to the training data containing the desired label",
)
parser<-add_argument(parser,
    "--features",short="-f", nargs="+",
    help="column names of features to match, must be present in input and training data",
)
parser<-add_argument(parser,
    "--label",short="-l", 
    help="column name of the label to match",
)
parser<-add_argument(parser,
    "--optimise",short="-o",flag=TRUE, 
    help="optimise the radius of the match in arcsec",
)
parser<-add_argument(parser,
    "--radius",short="-r",default=1, 
    help="radius of the match in arcsec",
)
parser<-add_argument(parser,
    "--sparse", default=1, 
    help="sparse-sample the training data by taking every n-th data point"
)
parser<-add_argument(parser,
    "--extname", default='OBJECTS', 
    help="open catalogue using this extension name"
)

#Get the arguments 
args<-parse_args(parser)
#Split features by space and comma 
args$features=helpRfuncs::vecsplit(args$features,",")
args$features=helpRfuncs::vecsplit(args$features," ")


cat("reading input data\n")
train_data = helpRfuncs::read.file(args$train, cols=c(args$features, args$label))
if (args$sparse>1) { 
  train_data = train_data[sample(nrow(train_data),size=nrow(train_data)/args$sparse),]
}
test_data = helpRfuncs::read.file(args$input,cols=c(args$features))

cat("running matching\n")

#Get typical comparison sample radial separations 
match<-list(ID=matrix(0,nrow=2,ncol=0))
rad=args$radius
if (args$optimise) { 
  cat(paste0("Using initial matching radius of  ",rad," arcsec\n"))
  match = celestial_coordmatch(coordref=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                                coordcompar=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                                rad=rad,ignoreexact=TRUE)
  
  if(ncol(match$ID)==0 || nrow(match$bestmatch)/nrow(match$ID) < 0.5) { 
    cat(paste0("estimating appropriate matching radius from training data:\n"))
    cat(paste0(rad," arcsec "))
    while(ncol(match$ID)==0 || nrow(match$bestmatch)/nrow(match$ID) < 0.5) { 
      rad=rad*5
      cat(paste0("- failed\n", rad," arcsec "))
      match = celestial_coordmatch(coordref=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                                    coordcompar=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                                    rad=rad,ignoreexact=TRUE)
    }
    cat(paste0("- success!\n"))
    rad = ceiling(quantile(match$bestmatch$sep,probs=pnorm(3)-pnorm(-3)))
    if (rad>=50 & rad < 3600) rad<-ceiling(rad/60)*60
    if (rad>3600) rad<-ceiling(rad/3600)*3600
    print(str(match))
    cat(paste0("Using final matching radius of  ",rad," arcsec\n"))
  }
} else { 
  rad<-args$radius
}
print(args$features)
print(str(data.frame(test_data[[args$features[1]]],test_data[[args$features[2]]])))
print(str(data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]])))
if (nrow(test_data)>1e7 | nrow(train_data)>1e7) { 
  nsplit<-ceiling(max(nrow(test_data),nrow(train_data))/1e7)
  cat(paste('using',nsplit,'splits'))
  ras<-quantile(test_data[[args$features[1]]],probs=seq(0,1,length=nsplit+1))
  ras[length(ras)]<-ras[length(ras)]+1e-10
  idx<-rep(0,nrow(test_data))
  for (i in 1:nsplit) { 
    ind1<-which(test_data[[args$features[1]]]>=ras[i] & test_data[[args$features[1]]]<ras[i+1])
    ind2<-which(train_data[[args$features[1]]]>=ras[i]-rad*2/3600 & train_data[[args$features[1]]]<ras[i+1]+rad*2/3600)
    cat(paste0('split ',i,": ",length(ind1)," ",length(ind2),"\n"))
    indx_tmp<- celestial_coordmatch(coordref=data.frame(test_data[[args$features[1]]][ind1],test_data[[args$features[2]]][ind1]), 
                                     coordcompar=data.frame(train_data[[args$features[1]]][ind2],train_data[[args$features[2]]][ind2]),
                                     rad=rad,radunit='asec',kstart=2)
    if (ncol(indx_tmp$ID)!=0) idx[ind1][which(indx_tmp$ID[,1]!=0)]<-ind2[indx_tmp$ID[,1]]
  }
  if (all(idx==0)) stop("There are no matches?!")
} else {
  idx = celestial_coordmatch(coordref=data.frame(test_data[[args$features[1]]],test_data[[args$features[2]]]), 
                              coordcompar=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                              rad=rad,radunit='asec')
  if (ncol(idx$ID)==0) stop("There are no matches?!") 
  idx <- idx$ID[,1]
}

if (length(idx) != nrow(test_data)) { 
  stop("Output match IDs not of same length as queried locations?!") 
}

cat(paste0("There are ",length(which(idx!=0))," matches out of ",nrow(test_data),"(",round(digits=2,100*length(which(idx!=0))/nrow(test_data)),"%)\n"))

prediction = train_data[[args$label]][idx]

if (length(prediction)!=nrow(test_data)) { 
  warning("There are un-matched sources! These will be assigned a value of -999!") 
  test_data[[args$label]] <- -999 
  test_data[[args$label]][which(idx!=0)] <- prediction
} else { 
  test_data[[args$label]] = prediction
}


cat("writing output data\n")
helpRfuncs::write.file(test_data,file=args$output)

