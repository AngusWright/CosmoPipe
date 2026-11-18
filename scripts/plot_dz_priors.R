library(argparser)

parser<-arg_parser("Plot the joint mean-redshift and width priors from compute_dz_priors.")
parser<-add_argument(parser,"--bias",help="joint wSig_ bias vector (mean biases, then width biases)")
parser<-add_argument(parser,"--covariance",help="joint wSig_ covariance matrix")
parser<-add_argument(parser,"--tomolims",nargs=Inf,type="numeric",
                     help="ordered tomographic bin edges")
parser<-add_argument(parser,"--output",help="directory for the four output PDFs")
parser<-add_argument(parser,"--patch",default="",help="patch name for plot titles")
args<-parse_args(parser)

for (name in c("bias","covariance","output")) {
  if (is.na(args[[name]]) || !nzchar(args[[name]])) stop(paste("--",name," is required",sep=""))
}
if (length(args$tomolims)<2 || any(!is.finite(args$tomolims)) ||
    any(diff(args$tomolims)<=0)) {
  stop("--tomolims must contain at least two finite, strictly increasing bin edges")
}
nbin<-length(args$tomolims)-1L
read_matrix<-function(file) {
  values<-unname(as.matrix(read.table(file,header=FALSE,check.names=FALSE)))
  if (!is.numeric(values) || any(!is.finite(values))) {
    stop(paste("Expected finite numeric values in",file))
  }
  values
}
bias<-read_matrix(args$bias)
if (!any(dim(bias)==1L) || length(bias)!=2L*nbin) {
  stop("The joint bias vector must contain exactly 2 values per tomographic bin: means, then widths")
}
bias<-as.numeric(bias)
covariance<-read_matrix(args$covariance)
if (!identical(dim(covariance),c(2L*nbin,2L*nbin))) {
  stop("The joint covariance must have 2N rows and columns for N tomographic bins")
}
if (!isSymmetric(covariance,tol=1e-10) || any(diag(covariance)<0)) {
  stop("The covariance must be symmetric with non-negative diagonal variances")
}
uncertainty<-sqrt(diag(covariance))
variable<-uncertainty>0
if (any(covariance[!variable,,drop=FALSE]!=0)) {
  stop("A zero-variance parameter cannot have non-zero covariances")
}
correlation<-matrix(NA_real_,nrow(covariance),ncol(covariance))
if (any(variable)) {
  # plot_covcor displays square matrices as supplied, so normalise explicitly.
  correlation[variable,variable]<-cov2cor(covariance[variable,variable,drop=FALSE])
}
if (any(abs(correlation)>1+1e-8,na.rm=TRUE)) {
  stop("The covariance implies correlations outside [-1, 1]")
}
if (any(!variable)) {
  warning("Zero-variance parameters have undefined correlations; these cells will be grey")
}
if (!dir.exists(args$output) && !dir.create(args$output,recursive=TRUE)) {
  stop(paste("Cannot create output directory",args$output))
}

bins<-seq_len(nbin)
binlabels<-paste0(bins,"\n(",args$tomolims[bins],",",args$tomolims[bins+1L],"]")
prefix<-if (nzchar(args$patch)) paste0(args$patch,": ") else ""

plot_bias<-function(values,errors,file,title,ylab,colour) {
  pdf(file,width=max(6,nbin*0.9),height=5,title=paste0(prefix,title))
  on.exit(dev.off())
  par(mar=c(5.5,5,3,1),las=1)
  limits<-range(0,values-errors,values+errors)
  padding<-if (diff(limits)>0) diff(limits)*0.12 else 0.01
  magicaxis::magplot(bins,values,type="n",side=2,grid=FALSE,
                    xlim=c(0.5,nbin+0.5),ylim=limits+c(-padding,padding),
                    xlab="",ylab="",main=paste0(prefix,title))
  axis(1,at=bins,labels=binlabels,tcl=-0.3,cex.axis=0.85,gap.axis=0)
  mtext(expression("Tomographic bin ("*Z[B]*" interval)"),side=1,line=3.6)
  mtext(ylab,side=2,line=3.2,las=0)
  abline(h=0,lty=2,col="grey55")
  nonzero<-errors>0
  if (any(nonzero)) {
    magicaxis::magerr(bins[nonzero],values[nonzero],ylo=errors[nonzero],
                      col=colour,lwd=1.6)
  }
  points(bins,values,pch=21,bg=colour,col=colour,cex=1.25)
}

plot_matrix<-function(values,file,type) {
  iscor<-type=="cor"
  title<-if (iscor) "Joint correlation" else "Joint covariance"
  nparam<-nrow(values)
  colours<-colorRampPalette(c("#2166AC","#F7F7F7","#B2182B"))(101)
  limit<-if (iscor) 1 else max(abs(values))
  if (limit==0) limit<-1
  zlim<-c(-limit,limit)
  labels<-c(paste("mean",bins),paste("width",bins))
  pdf(file,width=max(8,nparam*0.45+2),height=max(6,nparam*0.45+1),
      title=paste0(prefix,title))
  on.exit(dev.off())
  layout(matrix(c(1,2),nrow=1),widths=c(5,1.2))
  par(mar=c(5.5,5.5,3.5,0.5),cex=0.85)
  if (iscor) {
    helpRfuncs::plot_covcor(values,type="cor",text=FALSE,col=colours,zlim=zlim,
                           axes=FALSE,xlab="",ylab="",asp=1,
                           xaxs="i",yaxs="i")
  } else {
    magicaxis::magimage(seq_len(nparam),seq_len(nparam),values,
                       magmap=FALSE,col=colours,zlim=zlim,axes=FALSE,
                       xlim=c(0.5,nparam+0.5),ylim=c(nparam+0.5,0.5),
                       xlab="",ylab="")
  }
  title(main=paste0(prefix,title))
  missing<-which(is.na(values),arr.ind=TRUE)
  if (nrow(missing)) {
    rect(missing[,1]-0.5,missing[,2]-0.5,missing[,1]+0.5,missing[,2]+0.5,
         col="grey85",border=NA)
  }
  if (nparam<=8 || (iscor && nparam<=14)) {
    xy<-expand.grid(seq_len(nparam),seq_len(nparam))
    finite<-is.finite(values)
    if (any(finite)) {
      text(xy[finite,1],xy[finite,2],
           labels=if (iscor) sprintf("%.2f",values[finite]) else
             formatC(values[finite],format="g",digits=2),
           col=ifelse(abs(values[finite])>0.6*limit,"white","black"),cex=0.8)
    }
  }
  axis(1,at=seq_len(nparam),labels=labels,las=2,tcl=-0.2)
  axis(2,at=seq_len(nparam),labels=labels,las=2,tcl=-0.2)
  abline(v=nbin+0.5,h=nbin+0.5,col="grey40",lwd=1.5)
  box()
  if (iscor && any(!variable)) {
    mtext("Grey: undefined correlation (zero variance)",side=3,line=0.3,cex=0.75)
  } else if (!iscor && all(values==0)) {
    mtext("All covariances are zero",side=3,line=0.3,cex=0.75)
  }
  par(mar=c(5.5,0.5,3.5,5),cex=0.85,las=1)
  gradient<-seq(-limit,limit,length.out=101)
  magicaxis::magimage(c(0,1),gradient,matrix(rep(gradient,each=2),nrow=2),
                     magmap=FALSE,col=colours,zlim=zlim,axes=FALSE,asp=NA,
                     xlab="",ylab="")
  magicaxis::magaxis(side=4)
  mtext(if (iscor) "Correlation" else "Covariance",side=3,line=0.8)
  box()
}

plot_bias(bias[bins],uncertainty[bins],file.path(args$output,"nzbias.pdf"),
          "Mean-redshift bias",expression(Delta*mu[z]~"(calibration - reference)"),"#2166AC")
plot_bias(bias[nbin+bins],uncertainty[nbin+bins],file.path(args$output,"width_bias.pdf"),
          "Redshift-width bias",expression(Delta*sigma[z]~"(calibration - reference)"),"#B2182B")
plot_matrix(covariance,file.path(args$output,"covariance.pdf"),"cov")
plot_matrix(correlation,file.path(args$output,"correlation.pdf"),"cor")
cat("Wrote dz prior plots to",args$output,"\n")
