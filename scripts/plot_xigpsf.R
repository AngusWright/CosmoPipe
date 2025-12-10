#=========================================
#
# File Name : plot_TPD.R
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Sat Dec  6 05:41:01 2025
#
#=========================================

library(argparser)

#Create the argument parser 
p <- arg_parser("Plot theory predictive distributions for a chain file")
# Add a positional argument
p <- add_argument(p, "--xipmvec", help="Observed xipm data vector")
# Add a positional argument
p <- add_argument(p, "--xipsfvec", help="Observed PSF correlation function data vector")
# Add a positional argument
p <- add_argument(p, "--xigpsfvec", help="Observed PSF-shear cross correlation data vector")
# Add a positional argument
p <- add_argument(p, "--covariance", help="Estimated covariance")
# Add an optional argument
p <- add_argument(p, "--thetamin", help="minimum theta for xipm",type='numeric',default=NA)
# Add an optional argument
p <- add_argument(p, "--thetamax", help="maximum theta for xipm",type='numeric',default=NA)
# Add an optional argument
p <- add_argument(p, "--nmax", help="Number of xipm bins",type='integer',default=NA)
# Add an optional argument
p <- add_argument(p, "--ntomo", help="Number of tomographic bins",type='integer')
# Add an optional argument
p <- add_argument(p, "--output", help="output pdf", default="plot_TPD.pdf")
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
# Add an optional argument
p <- add_argument(p, "--type", help="Upper or Lower half of the data vector", default="upper")
## Add a flag
#p <- add_argument(p, "--append", help="append to file", flag=TRUE)
## Add an optional argument
#p <- add_argument(p, "--xlabel", help="x-axis variable name",default='Radius (arcmin)')
## Add an optional argument
#p <- add_argument(p, "--ylabel", help="y-axis variable name",default=expression(xi^[sys]/xi^paste(Lambda*"CDM"))

#Read the arguments 
args<-parse_args(p)

#Get the number of correlations 
ncorr<-sum(seq(args$ntomo))

#Check for incorrect calling syntax
if (is.na(args$xipmvec)) { 
  stop(cat(print(p))) 
} 


#Read in the data vector 
dat<-helpRfuncs::read.file(file=args$xipmvec)
print(str(dat))
if (ncol(dat)>2) { 
  print(colnames(dat))
  radius<-c(dat$meanr,dat$meanr)
  dat<-data.frame(V1=c(dat$xip,dat$xim))
} else { 
  radius<-rep(rep(10^seq(log10(args$thetamin),log10(args$thetamax),len=args$nmax),ncorr),2)
}
#Get the number of data elements 
ndata<-nrow(dat)/ncorr/2
#Read in the data vector 
psf<-helpRfuncs::read.file(file=args$xipsfvec)
print(str(psf))
if (ncol(psf)>2) { 
  psf<-data.frame(V1=c(psf$xip,psf$xim))
}
#Read in the data vector 
gpsf<-helpRfuncs::read.file(file=args$xigpsfvec)
print(str(gpsf))
if (ncol(gpsf)>2) { 
  print(colnames(gpsf))
  gpsf<-data.frame(V1=c(gpsf$xip,gpsf$xim))
}

#Read the covariance matrix 
cov<-helpRfuncs::read.file(file=args$covariance,type='asc')
cov<-as.matrix(cov)

dat<-(gpsf$V1)*sqrt(radius)


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

#Plot data vector with theory samples 
start=0
#Define the ylimits of each panel 
#ylim=range(c(dat+sqrt(diag(cov))*3,dat-sqrt(diag(cov))*3))/10^mfact
ylims_upper<-list()
start_tmp<-0
mfact<-ceiling(median(log10(abs(dat[1:(length(dat)/2)]))))
#mfact<--5
for (i in 1:args$ntomo) { 
  ylim=c(Inf,-Inf)
  ylims_upper[[i]]=list()
  for (j in i:args$ntomo) { 
    ind<-start_tmp+1:ndata
    ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-1*sqrt(radius[ind])*sqrt(diag(cov)[ind]))/10^mfact)),
           max(c(ylim[2],dat[ind]/10^mfact,(+1*sqrt(radius[ind])*sqrt(diag(cov)[ind]))/10^mfact)))
    #ylim=c(min(c(ylim[1],(-3*sqrt(diag(cov)[ind]))/10^mfact)),
    #       max(c(ylim[2],(+3*sqrt(diag(cov)[ind]))/10^mfact)))
    start_tmp<-start_tmp+ndata
  }
  for (j in i:args$ntomo) { 
    ylims_upper[[i]][[j]]<-ylim
  }
}
ylims_lower<-list()
for (i in 1:args$ntomo) ylims_lower[[i]]=list()
mfact<-ceiling(median(log10(abs(dat[length(dat)/2 + 1:(length(dat)/2)]))))
#mfact<--5
for (jj in 1:args$ntomo) { 
  start_tmp<-length(dat)/2
  for (i in 1:args$ntomo) { 
    for (j in i:args$ntomo) { 
      ind<-start_tmp+1:ndata
      if (j==jj) {  
        cat(paste0("[",i,",",j,"] "))
        ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-1*sqrt(radius[ind])*sqrt(diag(cov)[ind]))/10^mfact)),
               max(c(ylim[2],dat[ind]/10^mfact,(+1*sqrt(radius[ind])*sqrt(diag(cov)[ind]))/10^mfact)))
      }
      start_tmp<-start_tmp+ndata
    }
  }
  cat("\n")
  for (i in 1:jj) { 
    ylims_lower[[i]][[jj]]<-ylim
  }
}
print(ylims_lower)

for (uplo in 1:2) { 
  #Define the scaling factor for the y-labels 
  mfact<-ceiling(median(log10(abs(dat[length(dat)/2*(uplo-1) + 1:(length(dat)/2)]))))
  #mfact<--5
  for (i in 1:args$ntomo) { 
    for (j in i:args$ntomo) { 
      ind<-start+1:ndata
      #Plot the data vector 
      if (uplo==1){ 
        labels=c(F,F,i==1,j==args$ntomo)
        ylim=ylims_upper[[i]][[j]]
      } else { 
        labels=c(j==args$ntomo,i==1,F,F)
        ylim=ylims_lower[[i]][[j]]
      } 
      plot(radius[ind],dat[ind]/10^mfact,xlab='',ylab='',type='n',
           axes=F,ylim=ylim,log='x',xlim=range(radius))
      polygon(col=rgb(232,243,247,maxColorValue=255),border=NA,
              x=c(radius[ind],rev(radius[ind])),
              y=c(-1*sqrt(radius[ind])*sqrt(diag(cov)[ind])/10^mfact,
              rev( 1*sqrt(radius[ind])*sqrt(diag(cov)[ind])/10^mfact)))
      #Zero line 
      abline(h=0,lwd=1,lty=3)
      lines(col=rgb(238,87,75,maxColorValue=255),radius[ind],dat[ind]/10^mfact,lwd=1.5)

      magicaxis::magaxis(side=1:4,labels=labels,xlab='',ylab='',grid=FALSE)
  
      start=start+ndata
    }
  }
  if (uplo==1) { 
    mtext(side=4,text=bquote(.(parse(text="xi['+']^'gpsf'*sqrt(theta)")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)
  } else if (uplo==2) {  
    mtext(side=2,text=bquote(.(parse(text="xi['-']^'gpsf'*sqrt(theta)")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)
  }
}
#Annotate axes 
mtext(side=1,text=args$xlabel,line=2.5,outer=T)
mtext(side=3,text=args$xlabel,line=2.5,outer=T)

dev.off()

