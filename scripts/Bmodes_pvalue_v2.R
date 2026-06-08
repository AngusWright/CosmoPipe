
library(argparser) 

on.exit(traceback())

p <- arg_parser('Calculate bmodes')
p <- add_argument(p,"--inputfile",  help="Input file")
p <- add_argument(p,"--statistic", help="Statistic")
p <- add_argument(p,"--ntomo", , type='numeric', help="Number of tomographic bins")
p <- add_argument(p,"--thetamin", , type='numeric', help="Minimum theta")
p <- add_argument(p,"--thetamax",  type='numeric', help="Maximum theta")
p <- add_argument(p,"--output_dir",  help="Output directory")
p <- add_argument(p,"--title",  help="Plot title")
p <- add_argument(p,"--suffix",  help="Plot title suffix")
p <- add_argument(p,"--mult",  type='numeric', help="Multiplicative factor applied to the chi2 before calculating the p-value")   

args <- parse_args(p,argv=commandArgs(TRUE))
inputfile = args$inputfile
statistic = args$statistic
ntomo = args$ntomo
thetamin = args$thetamin
thetamax = args$thetamax
output_dir = args$output_dir
title = args$title
suffix = args$suffix
mult = args$mult

pvalue<-function(data, cov, mask=FALSE, mult=1.0) {
  if (any(mask)) {
    n_data = length(which(mask))
  } else {
    n_data = length(data)
    mask = rep(TRUE,n_data)
  }
  if (any(dim(cov)!=length(mask))) stop(paste("mask/cov mismatch:",paste(collapse=' ',dim(cov)),length(mask)))
  chi2 = `%*%`(data[mask],`%*%`(solve(mult^2*cov[mask,mask]),data[mask]))
  p = 1-pchisq(chi2, n_data)
  return(p)
}

plot_bmodes<-function(x_data, y_data, y_data_plot, y_error, cov, bin1_data, bin2_data, angbin, outfile, ylabel, ntomo, mult = NA){
  if (!is.na(mult)) { 
    factor = mult
  } else {
    factor = 1.0
  }
  if (!is.na(mult)){
    outfile=paste0(outfile , '_mult_v2_R.pdf')
  } else {
    outfile=paste0(outfile , '_v2_R.pdf')
  }
  if (ntomo != 1) {
    helpRfuncs::open_plot(height=4,width=9,file=outfile)
    par(mar=c(0,0,0,0),oma=c(3,4,3,2),family='serif')
    layout(matrix(seq(3*7),ncol=7,nrow=3,byrow=T))
  } else {
    helpRfuncs::open_plot(height=3,width=5,file=outfile)
    par(mar=c(0,0,0,0),oma=c(3,4,3,2),family='serif')
    # Convert to array to make indexing work
  }
  bincount=1
  ylim=c(min(y_data_plot-y_error*2.0),max(y_data_plot+y_error*2.0))
  if (min(ylim)>-diff(range(ylim))/3) ylim[1]<--diff(range(ylim))/3
  for (bin1 in seq(ntomo)){
    for (bin2 in seq(bin1,ntomo)){
      idx = which((bin1_data==bin1) & (bin2_data==bin2))
      magicaxis::magplot(x_data[idx], y_data_plot[idx],side=1:4,log=paste0(ifelse(xscale=='log','x','')),ylim=ylim,lwd=2,pch=20,
                         xlab='',ylab='',majorn=3,cex.axis=1.5,
                         labels=c(ntomo==1 | bincount>n_combinations*2/3,bincount%in%(n_combinations*c(0,1,2)/3+1),F,F),
                         grid=F,family='serif')
      magicaxis::magerr( x_data[idx], y_data_plot[idx], ylo=factor*y_error[idx],lwd=2)
      loc=helpRfuncs::text.coord('topleft',inset=0.1)
      text(loc[1],loc[2], sprintf('zbin %d-%d',bin1,bin2),pos=4)
      abline(h=0, col='black', lty=2)
      p = pvalue(y_data, cov,  mask=((bin1_data==bin1) & (bin2_data==bin2)), mult=factor)
      loc=helpRfuncs::text.coord('bottomleft',inset=0.1)
      if (p > 1e-2){
        text(loc[1],loc[2], parse(text=sprintf('italic(p) == %.2f',p)),pos=4)
      } else {
        text(loc[1],loc[2], parse(text=sprintf('italic(p) == "%.2e"',p)),pos=4)
      }
      if (statistic == 'cosebis'){
        p_nmax6 = pvalue(y_data, cov,  mask=((bin1_data==bin1) & (bin2_data==bin2) & (angbin<=6)), mult=factor)
        loc=helpRfuncs::text.coord('bottomleft',inset=c(0.1,0.2))
        if (p_nmax6 > 1e-2){
          text(loc[1],loc[2], parse(text=sprintf('italic(p) == %.2f',p_nmax6)), col='blue',pos=4)
        } else {
          text(loc[1],loc[2], parse(text=sprintf('italic(p) == "%.2e"',p_nmax6)), col='blue',pos=4)
        }
      } else if (statistic == 'xiEB'){
        p_nmax6 = pvalue(y_data, cov,  mask=((bin1_data==bin1) & (bin2_data==bin2) & (x_data<=100)), mult=factor)
        loc=helpRfuncs::text.coord('bottomleft',inset=c(0.1,0.2))
        if (p_nmax6 > 1e-2){
          text(loc[1],loc[2], parse(text=sprintf('italic(p) == %.2f',p_nmax6)), col='blue',pos=4)
        } else {
          text(loc[1],loc[2], parse(text=sprintf('italic(p) == "%.2e"',p_nmax6)), col='blue',pos=4)
        }
      }
      bincount=bincount+1
    }
  }
  mtext(side=2,outer=TRUE,line=2,text=parse(text=ylabel),family='serif')
  mtext(side=1,outer=TRUE,line=2,text=parse(text=xlabel),family='serif')
  #text(0.07, 0.9, sprintf('%s %s %s, theta=[%.2f,%.2f]',title,suffix,statistic,thetamin,thetamax) , col='red')
  p = pvalue(y_data, cov, mult=factor)
  if (ntomo != 1) {
    if (statistic == 'cosebis'){
      if (p > 1e-2){
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('n[max]*"=20"*"  "*italic(p) == %.2f',p)), col='black',line=0)
      } else {
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('n[max]*"=20"*"  "*italic(p) == "%.2e"',p)), col='black',line=0)
      }
    } else { 
      if (p > 1e-2){
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('"All data"*"  "*italic(p) == %.2f',p)), col='black',line=0)
      } else {
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('"All data"*"  "*italic(p) == "%.2e"',p)), col='black',line=0)
      }
    }

    if (statistic == 'cosebis'){
      p_nmax6 = pvalue(y_data, cov, mask = (angbin <= 6), mult=factor)
      if (p_nmax6 > 1e-2){
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('n[max]*"=6"*"   "*italic(p) == %.2f',p_nmax6)), col='blue',line=1.5)
      } else {
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('n[max]*"=6"*"   "*italic(p) == "%.2e"',p_nmax6)), col='blue',line=1.5)
      }
    } else if (statistic == 'xiEB'){
      p_nmax6 = pvalue(y_data, cov, mask = (x_data <= 100), mult=factor)
      if (p_nmax6 > 1e-2){
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('theta*"<100"*"   "*italic(p) == %.2f',p_nmax6)), col='blue',line=1.5)
      } else {
        mtext(side=3,outer=TRUE,adj=1, parse(text=sprintf('theta*"<100"*"   "*italic(p) == "%.2e"',p_nmax6)), col='blue',line=1.5)
      }
    }
  }
  dev.off()
}

if (statistic == 'cosebis'){
  extension = 'Bn'
  ylabel = 'italic(B)[italic(n)]~~group("[",10^-10~~rad^2,"]")'
  xlabel = 'italic(n)'
  xscale = 'linear'
}
if (statistic == 'bandpowers'){
  extension = 'PeeB'
  ylabel = 'italic(C)[BB](italic(l))/italic(l)~~group("[",10^-7,"]")'
  xlabel = 'italic(l)'
  xscale = 'log'
}
if (statistic == 'xiEB'){
  extension_plus = 'xiP'
  extension_minus = 'xiM'
  ylabel_plus = 'theta*xi[""+""]^B~~group("[",10^-4~~"arcmin","]")'
  ylabel_minus = 'theta*xi[""-""]^B~~group("[",10^-4~~"arcmin","]")'
  xlabel = 'theta'
  xscale = 'log'
}

f<-Rfits::Rfits_read_all(inputfile)

if (statistic != 'xiEB'){
  B_data = f[[extension]]
  print(range(as.numeric(B_data[['BIN1']])))
  n_data = length(B_data$VALUE)
  B_cov = f[['COVMAT']]$imDat[(n_data+1):nrow(f[['COVMAT']]$imDat),(n_data+1):ncol(f[['COVMAT']]$imDat)]
  B_std = sqrt(diag(B_cov))
} else {
  B_data_plus = f[[extension_plus]]
  B_data_minus = f[[extension_minus]]
  B_data_plusminus = c(B_data_plus[['VALUE']],B_data_minus[['VALUE']])
  n_data = length(B_data_plus$VALUE)
  B_cov_plus = f[['COVMAT']]$imDat[1:n_data,1:n_data]
  B_cov_minus = f[['COVMAT']]$imDat[(n_data+1):nrow(f[['COVMAT']]$imDat),(n_data+1):ncol(f[['COVMAT']]$imDat)]
  B_std_plus = sqrt(diag(B_cov_plus))
  B_std_minus = sqrt(diag(B_cov_minus))
  B_cov_plusminus = f[['COVMAT']]$imDat
  B_std_plusminus = sqrt(diag(B_cov_plusminus))
}

n_combinations = (ntomo*(ntomo+1)/2)
n_data_per_bin = (n_data / n_combinations)

if (suffix!="") {
  outfile = paste0(output_dir,sprintf('/bmodes_%.2f-%.2f_%s',thetamin,thetamax,suffix))
} else {
  outfile = paste0(output_dir,sprintf('/bmodes_%.2f-%.2f',thetamin,thetamax))
}

if (statistic == 'cosebis'){

  plot_bmodes(x_data=B_data[['ANG']], y_data=B_data[['VALUE']], y_data_plot=B_data[['VALUE']]*1e10, y_error=B_std*1e10, cov=B_cov, bin1_data=B_data[['BIN1']], bin2_data=B_data[['BIN2']], angbin=as.numeric(B_data[['ANGBIN']]), outfile=outfile, ylabel=ylabel, ntomo = ntomo)

  if (!is.na(mult)){
    plot_bmodes(x_data=B_data[['ANG']], y_data=B_data[['VALUE']], y_data_plot=B_data[['VALUE']]*1e10, y_error=B_std*1e10, cov=B_cov, bin1_data=B_data[['BIN1']], bin2_data=B_data[['BIN2']], angbin=B_data[['ANGBIN']], outfile=outfile, ylabel=ylabel, ntomo = ntomo, mult=mult)
  }

}
if (statistic == 'bandpowers'){
  plot_bmodes(x_data=B_data[['ANG']], y_data=B_data[['VALUE']], y_data_plot=B_data[['VALUE']]/B_data[['ANG']]*1e7, y_error=B_std/B_data[['ANG']]*1e7, cov=B_cov, bin1_data=B_data[['BIN1']], bin2_data=B_data[['BIN2']], angbin=B_data[['ANGBIN']], outfile=outfile, ylabel=ylabel, ntomo = ntomo)
  if (!is.na(mult)){
    plot_bmodes(x_data=B_data[['ANG']], y_data=B_data[['VALUE']], y_data_plot=B_data[['VALUE']]/B_data[['ANG']]*1e7, y_error=B_std/B_data[['ANG']]*1e7, cov=B_cov, bin1_data=B_data[['BIN1']], bin2_data=B_data[['BIN2']], angbin=B_data[['ANGBIN']], outfile=outfile, ylabel=ylabel, ntomo = ntomo, mult=mult)
  }
}

if (statistic == 'xiEB') {
  if (suffix!=''){
    outfile_plus = paste0(output_dir,sprintf('/bmodes_xiEB_plus_%.2f-%.2f_%s',thetamin,thetamax,suffix))
    outfile_minus = paste0(output_dir,sprintf('/bmodes_xiEB_minus_%.2f-%.2f_%s',thetamin,thetamax,suffix))
  } else {
    outfile_plus = paste0(output_dir,sprintf('/bmodes_xiEB_plus_%.2f-%.2f',thetamin,thetamax))
    outfile_minus = paste0(output_dir,sprintf('/bmodes_xiEB_minus_%.2f-%.2f',thetamin,thetamax))
  }

  plot_bmodes(x_data=B_data_plus[['ANG']], y_data=B_data_plus[['VALUE']], y_data_plot=B_data_plus[['VALUE']]*B_data_plus[['ANG']]*1e4, y_error=B_std_plus*B_data_plus[['ANG']]*1e4, cov=B_cov_plus, bin1_data=B_data_plus[['BIN1']], bin2_data=B_data_plus[['BIN2']], angbin=B_data_plus[['ANGBIN']], outfile=outfile_plus, ylabel=ylabel_plus, ntomo = ntomo)
  plot_bmodes(x_data=B_data_minus[['ANG']], y_data=B_data_minus[['VALUE']], y_data_plot=B_data_minus[['VALUE']]*B_data_minus[['ANG']]*1e4, y_error=B_std_minus*B_data_minus[['ANG']]*1e4, cov=B_cov_minus, bin1_data=B_data_plus[['BIN1']], bin2_data=B_data_minus[['BIN2']], angbin=B_data_minus[['ANGBIN']], outfile=outfile_minus, ylabel=ylabel_minus, ntomo = ntomo)
  if (!is.na(mult)){
    plot_bmodes(x_data=B_data_plus[['ANG']], y_data=B_data_plus[['VALUE']], y_data_plot=B_data_plus[['VALUE']]*B_data_plus[['ANG']]*1e4, y_error=B_std_plus*B_data_plus[['ANG']]*1e4, cov=B_cov_plus, bin1_data=B_data_plus[['BIN1']], bin2_data=B_data_plus[['BIN2']], angbin=B_data_plus[['ANGBIN']], outfile=outfile_plus, ylabel=ylabel_plus, ntomo = ntomo, mult=mult)
    plot_bmodes(x_data=B_data_minus[['ANG']], y_data=B_data_minus[['VALUE']], y_data_plot=B_data_minus[['VALUE']]*B_data_minus[['ANG']]*1e4, y_error=B_std_minus*B_data_minus[['ANG']]*1e4, cov=B_cov_minus, bin1_data=B_data_plus[['BIN1']], bin2_data=B_data_minus[['BIN2']], angbin=B_data_minus[['ANGBIN']], outfile=outfile_minus, ylabel=ylabel_minus, ntomo = ntomo, mult=mult)
  }
}

if (statistic == 'xiEB') { 
  # Combine tomographic bins into a single bin and calculate pvalue
  if (ntomo != 1) {
    B_cov<-B_cov_plus
    B_data<-B_data_plus
    ylabel=ylabel_plus
    inv_B_cov = solve(B_cov)
    B_combined = rep(0,n_data_per_bin)
    inv_cov_combined = array(0,dim=c(n_data_per_bin,n_data_per_bin))
    for (k in seq(n_data_per_bin)){
      idx = which(B_data[['ANGBIN']]==k)
      B_combined[k] = weighted.mean(B_data[['VALUE']][idx], w=1/diag(B_cov[idx,idx]))
    }
  
    for (i in seq(n_combinations)-1){
      for (j in seq(i,n_combinations-1)){
        inv_cov_combined = inv_cov_combined+inv_B_cov[(i*n_data_per_bin+1):((i+1)*n_data_per_bin),(j*n_data_per_bin+1):((j+1)*n_data_per_bin)]
      }
    } 
    B_cov_combined = solve(inv_cov_combined)
    if (suffix!=''){
      outfile_combined = paste0(output_dir,sprintf('/bmodes_xiEB_plus_%.2f-%.2f_%s_onetomo',thetamin,thetamax,suffix))
    } else {
      outfile_combined = paste0(output_dir,sprintf('/bmodes_xiEB_plus_%.2f-%.2f_onetomo',thetamin,thetamax))
    }
    plot_bmodes(x_data=B_data[['ANG']][1:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined*B_data[['ANG']][1:n_data_per_bin]*1e4, y_error=sqrt(diag(B_cov_combined))*B_data[['ANG']][1:n_data_per_bin]*1e4, cov=B_cov_combined, bin1_data=B_data[['BIN1']][1:n_data_per_bin], bin2_data=B_data[['BIN2']][1:n_data_per_bin], angbin=B_data[['ANGBIN']][1:n_data_per_bin], outfile=outfile_combined, ylabel=ylabel, ntomo = 1)

    if (!is.na(mult)) { 
      plot_bmodes(x_data=B_data[['ANG']][1:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined*B_data[['ANG']][1:n_data_per_bin]*1e4, y_error=sqrt(diag(B_cov_combined))*B_data[['ANG']][1:n_data_per_bin]*1e4, cov=B_cov_combined, bin1_data=B_data[['BIN1']][1:n_data_per_bin], bin2_data=B_data[['BIN2']][1:n_data_per_bin], angbin=B_data[['ANGBIN']][1:n_data_per_bin], outfile=outfile_combined, ylabel=ylabel, ntomo = 1,mult=mult)
    }

    B_cov<-B_cov_minus
    B_data<-B_data_minus
    ylabel=ylabel_minus
    inv_B_cov = solve(B_cov)
    B_combined = rep(0,n_data_per_bin)
    inv_cov_combined = array(0,dim=c(n_data_per_bin,n_data_per_bin))
    for (k in seq(n_data_per_bin)){
      idx = which(B_data[['ANGBIN']]==k)
      B_combined[k] = weighted.mean(B_data[['VALUE']][idx], w=1/diag(B_cov[idx,idx]))
    }
  
    for (i in seq(n_combinations)-1){
      for (j in seq(i,n_combinations-1)){
        inv_cov_combined = inv_cov_combined+inv_B_cov[(i*n_data_per_bin+1):((i+1)*n_data_per_bin),(j*n_data_per_bin+1):((j+1)*n_data_per_bin)]
      }
    } 
    B_cov_combined = solve(inv_cov_combined)
    if (suffix!=''){
      outfile_combined = paste0(output_dir,sprintf('/bmodes_xiEB_minus_%.2f-%.2f_%s_onetomo',thetamin,thetamax,suffix))
    } else {
      outfile_combined = paste0(output_dir,sprintf('/bmodes_xiEB_minus_%.2f-%.2f_onetomo',thetamin,thetamax))
    }
  
    plot_bmodes(x_data=B_data[['ANG']][1:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined*B_data[['ANG']][1:n_data_per_bin]*1e4, y_error=sqrt(diag(B_cov_combined))*B_data[['ANG']][1:n_data_per_bin]*1e4, cov=B_cov_combined, bin1_data=B_data[['BIN1']][1:n_data_per_bin], bin2_data=B_data[['BIN2']][1:n_data_per_bin], angbin=B_data[['ANGBIN']][1:n_data_per_bin], outfile=outfile_combined, ylabel=ylabel, ntomo = 1, mult=mult)

    if (!is.na(mult)) { 
      plot_bmodes(x_data=B_data[['ANG']][1:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined*B_data[['ANG']][1:n_data_per_bin]*1e4, y_error=sqrt(diag(B_cov_combined))*B_data[['ANG']][1:n_data_per_bin]*1e4, cov=B_cov_combined, bin1_data=B_data[['BIN1']][1:n_data_per_bin], bin2_data=B_data[['BIN2']][1:n_data_per_bin], angbin=B_data[['ANGBIN']][1:n_data_per_bin], outfile=outfile_combined, ylabel=ylabel, ntomo = 1,mult=mult)
    }


  }
} else { 
  # Combine tomographic bins into a single bin and calculate pvalue
  if (ntomo != 1) {
    inv_B_cov = solve(B_cov)
    B_combined = rep(0,n_data_per_bin)
    inv_cov_combined = array(0,dim=c(n_data_per_bin,n_data_per_bin))
    for (k in seq(n_data_per_bin)){
      idx = which(B_data[['ANGBIN']]==k)
      B_combined[k] = weighted.mean(B_data[['VALUE']][idx], w=1/diag(B_cov[idx,idx]))
    }
  
    for (i in seq(n_combinations)-1){
      for (j in seq(i,n_combinations-1)){
        inv_cov_combined = inv_cov_combined+inv_B_cov[(i*n_data_per_bin+1):((i+1)*n_data_per_bin),(j*n_data_per_bin+1):((j+1)*n_data_per_bin)]
      }
    } 
    B_cov_combined = solve(inv_cov_combined)
    if (suffix!=''){
      outfile_combined = paste0(output_dir,sprintf('/bmodes_%.2f-%.2f_%s_onetomo',thetamin,thetamax,suffix))
    } else {
      outfile_combined = paste0(output_dir,sprintf('/bmodes_%.2f-%.2f_onetomo',thetamin,thetamax))
    }
    if (statistic == 'cosebis') {
      plot_bmodes(x_data=B_data[['ANG']][1:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined*1e10, y_error=sqrt(diag(B_cov_combined))*1e10, cov=B_cov_combined, bin1_data=B_data[['BIN1']][1:n_data_per_bin], bin2_data=B_data[['BIN2']][1:n_data_per_bin], angbin=B_data[['ANGBIN']][1:n_data_per_bin], outfile=outfile_combined, ylabel=ylabel, ntomo = 1, mult=mult)
    }
    if (statistic == 'bandpowers'){
      plot_bmodes(x_data=B_data[['ANG']][1:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined/B_data[['ANG']][1:n_data_per_bin]*1e7, y_error=sqrt(diag(B_cov_combined))/B_data[['ANG']][1:n_data_per_bin]*1e7, cov=B_cov_combined, bin1_data=B_data[['BIN1']][1:n_data_per_bin], bin2_data=B_data[['BIN2']][1:n_data_per_bin], angbin=B_data[['ANGBIN']][1:n_data_per_bin], outfile=outfile_combined, ylabel=ylabel, ntomo = 1, mult=mult)
    }
  }
}
