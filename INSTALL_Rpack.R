library('remotes')
qrequire<-function(...) suppressWarnings(suppressPackageStartupMessages(require(...)))
require.and.load<-function(name,githubrep,force=FALSE) {
    package.name<-tail(strsplit(name,'/')[[1]],1)
    loaded<-qrequire(package.name,character.only=TRUE)
    if (loaded && !missing(githubrep)) {
        description<-utils::packageDescription(package.name)
        force<-force || !identical(description$RemoteUsername,githubrep) ||
            !identical(description$RemoteRepo,strsplit(name,'/')[[1]][1])
    }
    if (!loaded || force) {
        if (!missing(githubrep)) {
            remotes::install_github(paste(githubrep,name,sep='/'),upgrade='always')
        } else {
            install.packages(name,repos='https://cloud.r-project.org/')
        }
        if (!qrequire(package.name,character.only=TRUE)) {
            stop(paste("Failed to install package",package.name))
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
