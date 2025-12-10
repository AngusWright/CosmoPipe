#=========================================
#
# File Name : plot_TPD.R
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Tue Nov 25 14:52:55 2025
#
#=========================================

library(argparser)
library(extrafont)

#Create the argument parser 
p <- arg_parser("Plot theory predictive distributions for a chain file")
# Add a positional argument
p <- add_argument(p, "--datavec", help="Observed data vector")
# Add a positional argument
p <- add_argument(p, "--xcoord", help="Catalogue with x-coordinates in the first column",nargs="+")
# Add a positional argument
p <- add_argument(p, "--xmultpower",type='numeric',help="power of x^a * y for plotting",nargs=1,default=0)
# Add a positional argument
p <- add_argument(p, "--xused", help="Ranges of the x-coordinates used in the analysis",nargs=2,type='numeric')
# Add a positional argument
p <- add_argument(p, "--onlyused", help="Only show ranges of the x-coordinates used in the analysis",flag=TRUE)
# Add a positional argument
p <- add_argument(p, "--covariance", help="Estimated covariance")
# Add a positional argument
p <- add_argument(p, "--tpds", help="Theory predictive distributions")
# Add an optional argument
p <- add_argument(p, "--ntomo", help="Number of tomographic bins",type='integer')
# Add an optional argument
p <- add_argument(p, "--sampler", help="Sampler used for the chain")
# Add an optional argument
p <- add_argument(p, "--output", help="output pdf", default="plot_TPD.pdf")
# Add an optional argument
p <- add_argument(p, "--xlabel", help="x-axis variable name")
# Add an optional argument
p <- add_argument(p, "--xunit", help="x-axis units",default='')
# Add an optional argument
p <- add_argument(p, "--ylabel", help="y-axis variable name")
# Add an optional argument
p <- add_argument(p, "--yunit", help="y-axis units",default='')
# Add an optional argument
p <- add_argument(p, "--labloc", help="location of bin annotation", default="topleft")
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
# Add an optional argument
p <- add_argument(p, "--bmode", help="plot the second half of the data vector", flag=TRUE)
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

#Remove the B-modes/xim 
if (args$bmode) { 
  index<-which(!1:nrow(dat) %in% 1:(nrow(dat)/2))
} else { 
  index<-which(1:nrow(dat) %in% 1:(nrow(dat)/2))
} 
dat<-dat[index,]
ndata<-nrow(dat)/ncorr
#define the x-coordinates 
args$xcoord<-helpRfuncs::vecsplit(args$xcoord,by=',')
manual <- TRUE
if (length(unlist(args$xcoord))>1) { 
  args$xcoord<-as.numeric(unlist(args$xcoord))
  #xcoord<-seq(log10(args$xcoord[1]),log10(args$xcoord[2]),len=args$xcoord[3])
  #xlog=FALSE
  #args$xused<-log10(args$xused)
  #unlog='x'
  #manual <- args$xcoord[2])/(args$xcoord[1]) < 50 
  xcoord<-10^seq(log10(args$xcoord[1]),log10(args$xcoord[2]),len=args$xcoord[3])
  xlog=FALSE
  args$xused<-(args$xused)
  unlog=''
} else if (length(args$xcoord)==1 & file.exists(args$xcoord)) { 
  #Read in the x-coordinates 
  xcoord<-helpRfuncs::read.file(file=args$xcoord)[[1]]
  xlog=TRUE
  unlog='x'
} else { 
  xcoord<-seq(ndata)
  xlog=FALSE
  unlog=''
}
if (args$xmultpower!=0) { 
  dat<-dat*xcoord^args$xmultpower
}

#Read the covariance matrix 
cov<-helpRfuncs::read.file(file=args$covariance,type='text')
cov<-as.matrix(cov)
#Remove the B-modes/xim 
cov<-cov[index,index]

#Read the theory predictive distributions 
tpd<-helpRfuncs::read.chain(file=args$tpds)
#Read the samples for each theory prediction 
samps<-helpRfuncs::read.chain(file=sub("_list_","_",args$tpds))
#Assign the weights to the theory predictions 
tpdweight<-samps$weight
if (length(tpdweight)==0) { 
  tpdweight<-exp(samps$log_weight)
}
if (length(tpdweight)==0) { 
  tpdweight<-samps$post
  tpdweight[which(tpdweight<quantile(tpdweight,prob=0.01))]<-quantile(tpdweight,prob=0.01)
  tpdweight<-tpdweight/min(tpdweight,na.rm=T)
}
#Check sizes match 
if (length(tpdweight)!=nrow(tpd)) { 
  stop(paste("TPD sample weights are not of the same length as the sample?!\n",length(tpdweight),"!=",nrow(tpd)))
}
#Select only the theory predictions, and convert to matrix format 
cols<-colnames(tpd)
cols<-cols[which(grepl("scale_cuts_output",cols,ignore.case=T))]
tpd<-as.matrix(tpd[,cols,with=F])
if (args$bmode) { 
  if (ncol(tpd)>nrow(dat)) { 
    tpd<-tpd[,index]
  } else { 
    tpd<-NULL
  } 
}


#Define the layout matrix for the figure 
ncor<-(args$ntomo*(args$ntomo+1))/2
mat<-matrix(1:(args$ntomo*(args$ntomo+1)/2),nrow=3,ncol=ncor/3,byrow=T)

#open the plot device 
pdf(file=args$output,height=4,width=10)
#set the layout 
layout(mat)
#set the margins 
par(mar=c(0,0,0,0),oma=c(4,4.5,1,1),family='serif')

#Define the scaling factor for the y-labels 
mfact<-ceiling(median(log10(abs(dat$V1))))

#Define the ylimits of each panel 
ylim<-matrix(0,nrow=nrow(mat),ncol=2)
for (i in 1:nrow(mat)) { 
  ind<-((i-1)*ncol(mat)*ndata+1):(i*ncol(mat)*ndata)
  print(ind)
  ylim[i,1]<-min(c(ylim[i,1],(min(dat[ind]-xcoord^args$xmultpower*sqrt(diag(cov)[ind])*1.4)/10^mfact)))
  ylim[i,2]<-max(c(ylim[i,2],(max(dat[ind]+xcoord^args$xmultpower*sqrt(diag(cov)[ind])*1.4)/10^mfact)))
}
#Plot data vector with theory samples 
start=0
count=0
for (i in 1:args$ntomo) { 
  for (j in i:args$ntomo) { 
    count=count+1
    ind<-start+1:ndata
    #Plot the data vector 
    yind<-ceiling(count/ncol(mat)-1e-6)
    if (xlog) { 
      if (args$onlyused) { 
        xlim<-10^(range(log10(args$xused))+c(-1,1)*diff(log10(xcoord))[1])
      } else { 
        xlim<-10^(range(log10(xcoord))+c(-1,1)*diff(log10(xcoord))[1])
      } 
    } else { 
      if (args$onlyused) { 
        xlim<-range(args$xused)+c(-1,1)*diff(xcoord)[1]/2
      } else { 
        xlim<-range(xcoord)+c(-1,1)*diff(xcoord)[1]/2
      }
      #xlim<-c(min(xcoord)-diff(xcoord)[1]/2,6.5)
    }
    print(xlim)
    print(str(xcoord))
    print(str(dat$V1[ind]))
    plot(axes=F,xlab='',ylab='',xcoord,dat$V1[ind]/10^mfact,type='n',log=ifelse(xlog,'x',''),ylim=ylim[yind,],xlim=xlim)
    #Mask unused regions 
    if (length(args$xused)==2) { 
      #Ylimits
      ybottom<-min(ylim)-abs(diff(ylim))
      ytop=max(ylim)+abs(diff(ylim))
      #Xlimits
      if (xlog) { 
        xleft<-10^(min(log10(xlim))-5*abs(min(log10(xlim))-min(log10(xcoord))))
        xright<-10^(log10(args$xused[1]))#-diff(log10(xcoord))[1]/2)
      } else { 
        xleft<-min(xlim)-5*abs(min(xlim)-min(xcoord))
        xright<-args$xused[1]-diff(xcoord)[1]/2
      }
      print(c(xleft,xright,ybottom,ytop))
      rect(xl=xleft,xr=xright,yb=ybottom,yt=ytop,border=NA,col='grey')
      #Xlimits
      if (xlog) { 
        xright<-10^(max(log10(xlim))+5*abs(max(log10(xlim))-max(log10(xcoord))))
        xleft<-10^(log10(args$xused[2]))#+rev(diff(log10(xcoord)))[1]/2)
      } else { 
        xright<-max(xlim)+5*abs(max(xlim)-max(xcoord))
        xleft<-args$xused[2]+rev(diff(xcoord))[1]/2
      }
      print(c(xleft,xright,ybottom,ytop))
      rect(xl=xleft,xr=xright,yb=ybottom,yt=ytop,border=NA,col='grey')
    }

    #Zero line 
    abline(h=0,lwd=2)

    #Add the samples 
    if (length(tpd)>0) { 
      #tpdsamp<-tpd[sample(nrow(tpd),prob=tpdweight,size=500),]
      #matplot(xcoord,xcoord^args$xmultpower*t(tpdsamp)[ind,]/10^mfact,add=T,type='l',col=hsv(a=0.1),lty=1)
      cat("TPDs\n")
      print(str(tpd))
      print(str(xcoord))
      print(str(args$xmultpower))
      ymat<-xcoord^args$xmultpower*t(tpd)/10^mfact
      print(str(ymat))
      print(str(tpdweight))
      yquan<-matrix(NA,nrow=length(ind),ncol=6)
      for (ii in 1:length(ind)) {
        yquan[ii,]<-helpRfuncs::weighted.quantile(ymat[ind[ii],],weights=tpdweight,probs=pnorm(c(-1,1,-2,2,-3,3)),na.rm=TRUE)
        yquan[ii,]<-helpRfuncs::weighted.quantile(ymat[ind[ii],],weights=tpdweight,probs=pnorm(c(-1,1,-2,2,-3,3)),na.rm=TRUE)
      }
      print(str(xcoord))
      print(str(yquan))
      #polygon(c(xcoord,rev(xcoord)),c(yquan[,5],rev(yquan[,6])),border=hsv(a=0.4),col=hsv(a=0.4))
      polygon(c(xcoord,rev(xcoord)),c(yquan[,3],rev(yquan[,4])),border=hsv(a=0.4),col=seqinr::col2alpha("orange",0.8))
      polygon(c(xcoord,rev(xcoord)),c(yquan[,1],rev(yquan[,2])),border=hsv(a=0.4),col=hsv(a=0.8))
      #matplot(xcoord,xcoord^args$xmultpower*t(tpdsamp)[ind,]/10^mfact,add=T,type='l',col=hsv(a=0.1),lty=1)
      best<-ymat[ind,which.max(tpdweight)]*10^mfact/xcoord^args$xmultpower
      datr<-dat$V1[ind]/xcoord^args$xmultpower
      chi2<-(datr-best)%*%solve(cov[ind,ind])%*%(datr-best)
      pval<-1-pchisq(chi2,length(ind))
      cat(sprintf('zbin %d-%d: %f %.3f\n',i,j,chi2,pval))
    }

    #Data points
    points(xcoord,dat$V1[ind]/10^mfact,pch=20,cex=0.8,lwd=2)
    magicaxis::magerr(x=xcoord,dat$V1[ind]/10^mfact,
                      yhi=xcoord^args$xmultpower*sqrt(diag(cov)[ind])/10^mfact,
                      ylo=xcoord^args$xmultpower*sqrt(diag(cov)[ind])/10^mfact,lwd=2)
    loc=helpRfuncs::text.coord(args$labloc,inset=0.15)
    text(loc[1],loc[2], sprintf('zbin %d-%d',i,j),pos=ifelse(grepl("right",args$labloc),2,4),cex=1.5)
    #text(pos=4,x=xcoord[1],y=ylim[yind,2]+diff(ylim[yind,])/10,labels=paste0(i,"-",j),font=1)
    if (!manual) { 
      magicaxis::magaxis(xlab='',ylab='',side=1:4,majorn=3,cex.axis=1.5,unlog=unlog,
                         labels=c(count>ncor*2/3,count%in%(ncor*c(0,1,2)/3+1),F,F),
                         grid=F,family='serif')
    } else { 
      helpRfuncs::magaxis(xlab='',ylab='',side=1:4,majorn=3,cex.axis=1.5,unlog=unlog,
                         labels=c(count>ncor*2/3,count%in%(ncor*c(0,1,2)/3+1),F,F),
                         grid=F,family='serif',usemultloc=FALSE)
    }
    start=start+ndata
  }
}
#Annotate axes 
#mtext(side=3,text=args$xlabel,line=2.5,outer=T)
#mtext(side=4,text=bquote(.(parse(text=args$ylabel)[[1]])*" x10"^.(mfact)),line=2.5,outer=T)

#Annotate axes 
par(family='serif')
print(args$ylabel)
if (args$xunit!="") { 
  xlab<-paste0(args$xlabel,"*' ['*",args$xunit,"*']'")
} else { 
  xlab<-args$xlabel
} 
mtext(side=1,text=parse(text=xlab),line=2.5,outer=T,cex=1.5)
ylab<-args$ylabel
if (args$xmultpower!=-1 & (args$xmultpower!=0) & args$xmultpower!=1) { 
  ylab<-paste0(args$xlabel,"^",args$xmultpower,"*",ylab)
} else if (args$xmultpower==1) { 
  ylab<-paste0(args$xlabel,"*",ylab)
} else if (args$xmultpower==-1) { 
  ylab<-paste0(ylab,"/",args$xlabel)
}
if (mfact!=0) { 
  ylab<-paste0(ylab,"*' '%*% 10^",mfact)
}
if (args$yunit!="") { 
  ylab<-paste0(ylab,"*' ['*",args$yunit,"*']'")
} 
mtext(side=2,text=parse(text=ylab),line=2.0,outer=T,cex=1.5)

dev.off()

print('Done!')

