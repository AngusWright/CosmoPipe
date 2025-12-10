#=========================================
#
# File Name : plot_TPD.R
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Tue Dec  2 23:04:28 2025
#
#=========================================

library(argparser)

#Create the argument parser 
p <- arg_parser("Plot theory predictive distributions for a chain file")
# Add a positional argument
p <- add_argument(p, "--datavec", help="Observed data vector")
# Add a positional argument
p <- add_argument(p, "--covariance", help="Estimated covariance")
# Add a positional argument
p <- add_argument(p, "--refdatavec", help="Reference data vector",default='')
# Add a positional argument
p <- add_argument(p, "--refcovariance", help="Reference covariance",default='')
# Add an optional argument
p <- add_argument(p, "--nmax", help="Number of modes/datapoints",type='integer',default=NA)
# Add an optional argument
p <- add_argument(p, "--refnmax", help="Number of modes/datapoints",type='integer',default=NA)
# Add an optional argument
p <- add_argument(p, "--ntomo", help="Number of tomographic bins",type='integer')
# Add an optional argument
p <- add_argument(p, "--output", help="output pdf", default="plot_TPD.pdf")
# Add a positional argument
p <- add_argument(p, "--xcoord", help="Catalogue with x-coordinates in the first column",nargs="+")
# Add an optional argument
p <- add_argument(p, "--xlabel", help="x-axis variable name")
# Add an optional argument
p <- add_argument(p, "--ylabel", help="y-axis variable name")
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
# Add an optional argument
p <- add_argument(p, "--type", help="Upper or Lower half of the data vector", default="upper")
## Add a flag
#p <- add_argument(p, "--append", help="append to file", flag=TRUE)

#Read the arguments 
args<-parse_args(p)

#Get the number of correlations 
ncorr<-sum(seq(args$ntomo))

#Check for incorrect calling syntax
if (is.na(args$datavec)) { 
  stop(cat(print(p))) 
} 


#Read in the data vector 
dat<-helpRfuncs::read.file(file=args$datavec)
#Get the number of data elements 
ndata<-nrow(dat)/ncorr
if (!is.na(args$nmax)) { 
  if (ndata!=args$nmax) { 
    if (args$type=='upper') { 
      #This means that the B-modes are there... 
      dat<-dat[1:(nrow(dat)/2),]
    } else { 
      #This means that the B-modes are there... 
      dat<-dat[((nrow(dat)/2)+1):nrow(dat),]
    } 
    ndata<-nrow(dat)/ncorr
  }
}

#Read the covariance matrix 
cov<-data.table::fread(file=args$covariance)
cov<-as.matrix(cov)

#define the x-coordinates 
args$xcoord<-helpRfuncs::vecsplit(args$xcoord,by=',')
if (length(unlist(args$xcoord))>1) { 
  args$xcoord<-as.numeric(unlist(args$xcoord))
  xcoord<-10^seq(log10(args$xcoord[1]),log10(args$xcoord[2]),len=args$xcoord[3])
} else if (length(args$xcoord)==1 & file.exists(args$xcoord)) { 
  #Read in the x-coordinates 
  xcoord<-helpRfuncs::read.file(file=args$xcoord)[[1]]
} else { 
  xcoord<-seq(ndata)
}
if (file.exists(args$refdatavec)) { 
  #Read in the data vector 
  ref<-helpRfuncs::read.file(file=args$refdatavec)
}
if (file.exists(args$refcovariance)) { 
  #Read the covariance matrix 
  refcov<-data.table::fread(file=args$refcovariance)
  refcov<-as.matrix(refcov)
}
if (exists("ref")) { 
  if (!is.na(args$refnmax)&!is.na(args$nmax)) { 
    if (args$refnmax!=args$nmax) { 
      refind<-rep(1:args$refnmax,ncorr)
      if (length(refind)!=nrow(ref)) { 
        print(length(refind))
        print(nrow(ref))
        print(paste(args$refnmax,"*",ncorr,"=",length(refind),"!=",nrow(ref)))
        stop("reference number of obs is not Ncorrfunc * Nmode?!")
      }
      ref<-ref[which(refind<=args$nmax),]
      refcov<-refcov[which(refind<=args$nmax),which(refind<=args$nmax)]
    }
  }
}

#Define the layout matrix for the figure 
#upper triangle 
mat<-matrix(0,nrow=args$ntomo+1,ncol=args$ntomo+1)
cumul<-0
for (i in 1:args$ntomo) { 
  mat[i,i:args$ntomo+1]<-i:args$ntomo + cumul
  cumul<-cumul+length(i:args$ntomo)-1
}
#lower triangle 
cumul<-cumul+args$ntomo
for (i in 1:args$ntomo) {
  mat[i:args$ntomo+1,i]<-i:args$ntomo + cumul
  cumul<-cumul+length(i:args$ntomo)-1
}

#open the plot device 
pdf(file=args$output)
#set the layout 
layout(mat)
#set the margins 
par(mar=c(0,0,0,0),oma=c(5,5,5,5))

#Define the scaling factor for the y-labels 
mfact<-ceiling(median(log10(abs(dat$V1))))

#Plot data vector with theory samples 
start=0
#Define the ylimits of each panel 
ylim=range(c(dat+sqrt(diag(cov))*3,dat-sqrt(diag(cov))*3))/10^mfact
for (i in 1:args$ntomo) { 
  for (j in i:args$ntomo) { 
    ind<-start+1:ndata
    #Plot the data vector 
    magicaxis::magplot(xcoord,dat$V1[ind]/10^mfact,xlab='',ylab='',type='n',side=1:4,labels=c(i==j,F,i==1,j==args$ntomo),
                       ylim=ylim,xlim=c(0.5,ndata+0.5),grid=F)
    #Zero line 
    abline(h=0,lwd=2)
    #Data points
    points(xcoord,dat$V1[ind]/10^mfact,pch=20,cex=0.8,lwd=2)
    magicaxis::magerr(x=xcoord,dat$V1[ind]/10^mfact,yhi=sqrt(diag(cov)[ind])/10^mfact,ylo=sqrt(diag(cov)[ind])/10^mfact,lwd=2)

    if (exists("ref")) { 
      #reference Data points
      points(x=xcoord,ref$V1[ind]/10^mfact,pch=20,cex=0.8,lwd=2,col='red3')
      magicaxis::magerr(x=xcoord,ref$V1[ind]/10^mfact,yhi=sqrt(diag(refcov)[ind])/10^mfact,ylo=sqrt(diag(refcov)[ind])/10^mfact,lwd=2,col='red3')
    }
    start=start+ndata
  }
}
#Annotate axes 
mtext(side=3,text=args$xlabel,line=2.5,outer=T)
mtext(side=4,text=bquote(.(parse(text=args$ylabel)[[1]])*" x10"^.(mfact)),line=2.5,outer=T)

#Sigma residuals of model w.r.t. data 
start=0
for (i in 1:args$ntomo) { 
  for (j in i:args$ntomo) { 
    ind<-start+1:ndata
    #Plot the data vector 
    magicaxis::magplot(1:length(ind),xlab='',ylab='',type='n',ylim=c(-4,4),xlim=c(0.5,ndata+0.5),side=1:4,labels=c(j==args$ntomo,i==1,i==j,F),grid=F)
    #Zero lone 
    abline(h=0,lwd=2)
    #Data 
    points(rep(0,length(ind)),pch=20,cex=0.8,lwd=2)
    magicaxis::magerr(x=1:length(ind),rep(0,length(ind)),yhi=rep(1,length(ind)),ylo=rep(-1,length(ind)),lwd=2)

    if (exists("ref")) { 
      #reference Data points
      points(x=1:length(ind)+0.25,(ref$V1[ind]-dat$V1[ind])/sqrt(diag(cov)[ind]),pch=20,cex=0.8,lwd=2,col='red3')
    }

    start=start+ndata
  }
}
#Annotate axes 
mtext(side=1,text=args$xlabel,line=2.5,outer=T)
mtext(side=2,text=bquote((.(parse(text=args$ylabel)[[1]])^dat-
                          .(parse(text=args$ylabel)[[1]])^ref)/
                          sigma[.(parse(text=args$ylabel)[[1]])*",dat"]),line=2.5,outer=T)

dev.off()

