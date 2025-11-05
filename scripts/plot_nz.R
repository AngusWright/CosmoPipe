#=========================================
#
# File Name : plot_nz.R
# Created By : awright
# Creation Date : 23-03-2023
# Last Modified : Fri Oct 17 10:25:10 2025
#
#=========================================

#Get the filelist from input
inputs<-commandArgs(TRUE) 

#Interpret the command line options 
while (length(inputs)!=0) {
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  print(inputs) 
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') { 
    #Read the input file(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      filelist<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      filelist<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--truth') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      truth.list<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      truth.list<-inputs
      inputs<-NULL
    } 
    truth.list<-helpRfuncs::vecsplit(truth.list,by=' ')
    #/*fold*/}}}
  } else if (inputs[1]=='--binstrings') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      binstrings<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      binstrings<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
outputbase<-helpRfuncs::vecsplit(filelist[1],by='/')
outputbase<-paste(outputbase[-length(outputbase)],collapse='/')
#Setup the layout image
npanel<-ceiling(length(binstrings)/3)*3
cat(paste("using",npanel,"panels\n"))

#Output the valid Nz plot {{{
cat("Plotting Nz\n")
png(file=paste0(outputbase,"_Nz.png"),height=2.5*(npanel/3)*220,width=10*220,res=220)
#set up panels 
layout(matrix(1:npanel,ncol=3,byrow=T))
par(mar=c(0,0,0,0),oma=c(4,4,1,1))
#Do we need an in-panel legend?
inplot=(npanel==length(binstrings))
#initialise the progressbar 
pb<-txtProgressBar(style=3,min=0,max=length(filelist))
count<-0
truth<-nz<-list()
xmax<-ymax<-0
#loop over the inputs 
for (tomo in 1:length(binstrings)) {
  #Get the files in this bin 
  binfiles<-which(grepl(binstrings[tomo],filelist,fixed=T))
  #initialise the nz list 
  truth[[tomo]]<-nz[[tomo]]<-list()
  if (length(binfiles)!=0) { 
    col.count<-0
    for (file in binfiles) {
      #Increment the colour counter
      col.count<-col.count+1
      #Update progress bar 
      count=count+1
      setTxtProgressBar(pb,count)
      #read the nz
      nz[[tomo]][[col.count]]<-helpRfuncs::read.file(filelist[file])
      #Get the ymax
      ymax<-max(c(max(nz[[tomo]][[col.count]]$density),ymax))
      #Get the xmax
      xmax<-max(c(nz[[tomo]][[col.count]]$binstart[min(which(cumsum(nz[[tomo]][[col.count]]$density)/sum(nz[[tomo]][[col.count]]$density)>0.99))],xmax))
    }
  }
  #Get the files in this bin of the truth 
  binfiles<-which(grepl(binstrings[tomo],truth.list,fixed=T))
  if (length(binfiles)!=0) { 
    col.count<-0
    for (file in binfiles) {
      #Increment the colour counter
      col.count<-col.count+1
      #Update progress bar 
      count=count+1
      setTxtProgressBar(pb,count)
      #read the nz
      truth[[tomo]][[col.count]]<-helpRfuncs::read.file(truth.list[file])
      #Get the ymax
      ymax<-max(c(max(truth[[tomo]][[col.count]]$density),ymax))
      #Get the xmax
      xmax<-max(c(truth[[tomo]][[col.count]]$binstart[min(which(cumsum(truth[[tomo]][[col.count]]$density)/sum(truth[[tomo]][[col.count]]$density)>0.99))],xmax))
    }
  }
}
#loop over the inputs 
for (tomo in 1:length(binstrings)) {
  #Get the files in this bin 
  binfiles<-which(grepl(binstrings[tomo],filelist,fixed=T))
  #Set up the plot panel
  magicaxis::magplot(1,xlim=c(0,xmax),ylim=c(0,ymax),type='n',xlab='',ylab='',side=1:4,labels=c(tomo>length(binstrings)-3,tomo%%3==1,F,F))
  if (length(binfiles)==0) { next }
  #Define the colors used 
  col<-colorRampPalette(RColorBrewer::brewer.pal(8,"RdBu"))(length(binfiles))
  #Define the alpha
  alpha<-1/min(3,length(binfiles))
  col.count<-0
  means<-rep(NA,length(binfiles))
  for (file in binfiles) {
    #Increment the colour 
    col.count<-col.count+1
    #Update progress bar 
    count=count+1
    setTxtProgressBar(pb,count)
    #read the nz
    #Draw the Nz 
    lines(nz[[tomo]][[col.count]]$binstart,nz[[tomo]][[col.count]]$density,col=seqinr::col2alpha(col[col.count],a=alpha),lwd=1)
    means[col.count]<-sum(nz[[tomo]][[col.count]]$binstart*nz[[tomo]][[col.count]]$density)
  }
  #Get the files in this bin 
  binfiles<-which(grepl(binstrings[tomo],truth.list,fixed=T))
  if (length(binfiles)>0) { 
    col.count<-0
    truth.means<-rep(NA,length(binfiles))
    for (file in binfiles) {
      #Increment the colour 
      col.count<-col.count+1
      #Update progress bar 
      count=count+1
      setTxtProgressBar(pb,count)
      #read the nz
      #Draw the Nz 
      lines(truth[[tomo]][[col.count]]$binstart,truth[[tomo]][[col.count]]$density,col=seqinr::col2alpha('black',a=0.8),lwd=1,lty=3)
      truth.means[col.count]<-sum(truth[[tomo]][[col.count]]$binstart*truth[[tomo]][[col.count]]$density)
    }
    if (length(means)==1) { 
      text(ymax*0.75,xmax*0.75,labels=bquote(delta[z]==.(round(digits=3,means-truth.means))))
    } else { 
      text(ymax*0.75,xmax*0.75,labels=bquote(delta[z]==.(round(digits=3,mean(means-truth.means)))*"±"*.(round(digits=3,sd(means-truth.means)))))
    } 
  } else { 
    if (length(means)==1) { 
      text(ymax*0.75,xmax*0.75,labels=bquote(mu[z]==.(round(digits=3,means))))
    } else { 
      text(ymax*0.75,xmax*0.75,labels=bquote(mu[z]==.(round(digits=3,mean(means)))*"±"*.(round(digits=3,sd(means)))))
    } 
  }
}
close(pb)
#Add the axes labels 
mtext(side=1,outer=T,text="redshift",line=3)
mtext(side=2,outer=T,text="PDF",line=2.5)
dev.off()
#}}}

