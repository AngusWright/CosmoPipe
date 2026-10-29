if (!requireNamespace('remotes', quietly = TRUE)) {
    install.packages('remotes', repos = 'https://cloud.r-project.org/')
}

library('remotes')
qrequire<-function(...) suppressWarnings(suppressPackageStartupMessages(require(...)))
require.and.load<-function(name,githubrep,force=FALSE) {
    if (!qrequire(name,character.only=TRUE) || force) {
        if (!missing(githubrep)) {
            remotes::install_github(paste(githubrep,name,sep='/'),upgrade='always')
        } else {
            install.packages(name,repos='https://cloud.r-project.org/')
        }
        if (grepl('/',name) & !missing(githubrep)) {
            name<-rev(strsplit(name,'/')[[1]])[1]
        }
        if (!qrequire(name,character.only=TRUE)) {
            stop(paste("Failed to install package",name))
        }
    }
}
require.and.load('data.table')
require.and.load('plotrix')
require.and.load('Rfits','ASGR')
require.and.load('helpRfuncs','AngusWright')
require.and.load('kohonen/kohonen','AngusWright')
require.and.load('RColorBrewer')
require.and.load('KernSmooth')
require.and.load('itertools')
require.and.load('matrixStats')
require.and.load('argparser')
require.and.load('seqinr')
