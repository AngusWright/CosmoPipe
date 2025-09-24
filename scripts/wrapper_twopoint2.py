

    ##############################
    ##  wrapper_twopoint2.py    ##
    ##  Chieh-An Lin            ##
    ##  Version 2020.02.19      ##
    ##############################


import numpy as np
import scipy.interpolate as itp
import astropy.io.fits as fits
sys.path.append("@RUNROOT@/INSTALL/kcap/modules/scale_cuts_new/")
import twopoint
import wrapper_twopoint as wtp


###############################################################################
## Functions related to mean & covariance

class TwoPointBuilder:
    
    def __init__(self,
                  nbTomoN=0,
                  nbTomoG=0,
                  nbObs=0,
                  N_theta_ee=9,
                  theta_min_ee=0.5,
                  theta_max_ee=300,
                  N_ell_ee=8,
                  ell_min_ee=100,
                  ell_max_ee=1500,
                  nbModes_ee=5,
                  N_theta_ne=9,
                  theta_min_ne=0.5,
                  theta_max_ne=300,
                  N_ell_ne=8,
                  ell_min_ne=100,
                  ell_max_ne=1500,
                  nbModes_ne=5,
                  N_theta_nn=9,
                  theta_min_nn=0.5,
                  theta_max_nn=300,
                  N_ell_nn=8,
                  ell_min_nn=100,
                  ell_max_nn=1500,
                  nbModes_nn=5,
                  prefix_Flinc=None,
                  prefix_CosmoSIS=None,
                  verbose=True,
                  nnAuto=False,
                  smbinAuto=True):
    
        ## File prefixes
        self.prefix_Flinc    = 'data/mockFootprint/' if prefix_Flinc is None else prefix_Flinc
        self.prefix_CosmoSIS = 'data/mockFootprint/milvus/cosmosis/' if prefix_CosmoSIS is None else prefix_CosmoSIS
        
        ## Customize the above for your own inference; but don't touch the below
        ########################################################################
        
        ## Tomographic bins
        self.nbTomoN = nbTomoN
        self.nbTomoG = nbTomoG
        self.nbObs   = nbObs
        
        ## Define angular bin parameters
        self.N_theta_ee   = N_theta_ee
        self.theta_min_ee = theta_min_ee
        self.theta_max_ee = theta_max_ee
    
        self.N_ell_ee     = N_ell_ee
        self.ell_min_ee   = ell_min_ee
        self.ell_max_ee   = ell_max_ee
        self.nbModes_ee   = nbModes_ee
        
        self.N_theta_ne   = N_theta_ne
        self.theta_min_ne = theta_min_ne
        self.theta_max_ne = theta_max_ne
    
        self.N_ell_ne     = N_ell_ne
        self.ell_min_ne   = ell_min_ne
        self.ell_max_ne   = ell_max_ne
        self.nbModes_ne   = nbModes_ne
        
        self.N_theta_nn   = N_theta_nn
        self.theta_min_nn = theta_min_nn
        self.theta_max_nn = theta_max_nn
    
        self.N_ell_nn     = N_ell_nn
        self.ell_min_nn   = ell_min_nn
        self.ell_max_nn   = ell_max_nn
        self.nbModes_nn   = nbModes_nn

        self.nnAuto     = nnAuto
        self.smbinAuto  = smbinAuto
        self.verbose    = verbose
        self.mean       = None
        self.cov        = None
        self.nobs       = None
        self.kernelList = None
        
        self.setAngBins()
        self.setNbPairs()
        return
    
    ## Initialize
    def setAngBins(self):
        bAndC_theta_ee = np.logspace(np.log10(self.theta_min_ee), np.log10(self.theta_max_ee), 2*self.N_theta_ee+1)
        self.theta_ee     = bAndC_theta_ee[1::2] ## [arcmin]
        self.bin_theta_ee = bAndC_theta_ee[0::2]
        bAndC_ell_ee = np.logspace(np.log10(self.ell_min_ee), np.log10(self.ell_max_ee), 2*self.N_ell_ee+1)
        self.ell_ee       = bAndC_ell_ee[1::2]
        self.bin_ell_ee   = bAndC_ell_ee[0::2]
        self.nArr_ee      = np.arange(self.nbModes_ee) + 1.0
        
        bAndC_theta_ne = np.logspace(np.log10(self.theta_min_ne), np.log10(self.theta_max_ne), 2*self.N_theta_ne+1)
        self.theta_ne     = bAndC_theta_ne[1::2] ## [arcmin]
        self.bin_theta_ne = bAndC_theta_ne[0::2]
        bAndC_ell_ne = np.logspace(np.log10(self.ell_min_ne), np.log10(self.ell_max_ne), 2*self.N_ell_ne+1)
        self.ell_ne       = bAndC_ell_ne[1::2]
        self.bin_ell_ne   = bAndC_ell_ne[0::2]
        self.nArr_ne      = np.arange(self.nbModes_ne) + 1.0
        
        bAndC_theta_nn = np.logspace(np.log10(self.theta_min_nn), np.log10(self.theta_max_nn), 2*self.N_theta_nn+1)
        self.theta_nn     = bAndC_theta_nn[1::2] ## [arcmin]
        self.bin_theta_nn = bAndC_theta_nn[0::2]
        bAndC_ell_nn = np.logspace(np.log10(self.ell_min_nn), np.log10(self.ell_max_nn), 2*self.N_ell_nn+1)
        self.ell_nn       = bAndC_ell_nn[1::2]
        self.bin_ell_nn   = bAndC_ell_nn[0::2]
        self.nArr_nn      = np.arange(self.nbModes_nn) + 1.0

        return
    
    def setNbPairs(self):
        if self.nnAuto:
            self.__nbPairsNN  = self.nbTomoN
            self.__pairListNN = [(i, i) for i in range(self.nbTomoN)]
        else:
            self.__nbPairsNN  = self.nbTomoN * (self.nbTomoN+1) // 2
            self.__pairListNN = [(i, j) for i in range(self.nbTomoN) for j in range(i, self.nbTomoN)]
        self.__nbPairsNG  = self.nbTomoN * self.nbTomoG
        self.__nbPairsGG  = self.nbTomoG * (self.nbTomoG+1) // 2
        self.__pairListNG = [(i, j) for i in range(self.nbTomoN) for j in range(self.nbTomoG)]
        self.__pairListGG = [(i, j) for i in range(self.nbTomoG) for j in range(i, self.nbTomoG)]
        
        self.__nbPairsONEPT  = self.nbObs
        self.__pairListONEPT = [(i, i) for i in range(self.nbObs)]
        
        print(self.__pairListNN, self.__pairListNG, self.__pairListGG, self.__pairListONEPT)
        print(self.__nbPairsNN, self.__nbPairsNG, self.__nbPairsGG, self.__nbPairsONEPT)
        
        return
    
    ## Mean
    def makeTomoAngDict(self):
        labConv = wtp.LabelConvention()
        tomoAngDict = { ## Don't touch the order of this list
            labConv.w:       [self.__pairListNN, self.N_theta_nn, self.theta_nn],
            labConv.gamma_t: [self.__pairListNG, self.N_theta_ne, self.theta_ne],
            labConv.gamma_x: [self.__pairListNG, self.N_theta_ne, self.theta_ne],
            labConv.xi_p:    [self.__pairListGG, self.N_theta_ee, self.theta_ee],
            labConv.xi_m:    [self.__pairListGG, self.N_theta_ee, self.theta_ee],
            labConv.P_nn:    [self.__pairListNN, self.N_ell_nn,   self.ell_nn],
            labConv.P_ne_E:  [self.__pairListNG, self.N_ell_ne,   self.ell_ne],
            labConv.P_ne_B:  [self.__pairListNG, self.N_ell_ne,   self.ell_ne],
            labConv.P_ee_E:  [self.__pairListGG, self.N_ell_ee,   self.ell_ee],
            labConv.P_ee_B:  [self.__pairListGG, self.N_ell_ee,   self.ell_ee],
            labConv.E_n:     [self.__pairListGG, self.nbModes_ee, self.nArr_ee],
            labConv.B_n:     [self.__pairListGG, self.nbModes_ee, self.nArr_ee],
            labConv.Psi_gm:  [self.__pairListNG, self.nbModes_ne, self.nArr_ne],
            labConv.Psi_gg:  [self.__pairListNN, self.nbModes_nn, self.nArr_nn],
        }
        
        assert len(tomoAngDict) == len(labConv.kernelTypeDict)
        return tomoAngDict
    
    def _makeMean_none(self, statsTag):
        labConv = wtp.LabelConvention()
        tomoAngDict = self.makeTomoAngDict()
        statsList = statsTag.split('+')
        statsList_complete = tomoAngDict.keys()
        
        for stats in statsList:
            if stats not in statsList_complete:
                raise ValueError('\"%s\" not allowed' % statsTag)
        
        stock = []
        
        for stats, line in tomoAngDict.items():
            pairList = line[0]
            N_ang    = line[1]
          
            if stats in statsList:
                stock += [0.0] * len(pairList) * N_ang
        return stock
    
    def _loadNpyDataMat_Flinc(self, aves, statsTag, randTag, verbose=True):
        labConv = wtp.LabelConvention()
        statsList = statsTag.split('+')
        stock = []
        
        for stats in statsList:
            stats_c = labConv.defaultToCustomStatsTag(stats)
            name = '%s%s/MFP_combDataMat/dataMat_%s_%s_full.npy' % (self.prefix_Flinc, aves, stats_c, randTag)
            data = np.load(name)
            stock.append(data)
            if verbose == True:
                print('Loaded \"%s\"' % name)
        
        ## Cut
        NList = [data.shape[0] for data in stock]
        N_min = min(NList)
        stock = [data[:N_min] for data in stock]
        stock = np.hstack(stock)
        
        if verbose == True:
            print('N = %s' % stock.shape[0])
        return stock
    
    def _makeMean_Flinc(self, aves, statsTag, verbose=True):
        data = self._loadNpyDataMat_Flinc(aves, statsTag, 'signal', verbose=verbose)
        mean = np.mean(data, axis=0)
        return mean
    
    def _interpolateCF(self, theta, x, y):
        inter = itp.interp1d(np.log10(x), x*y, bounds_error=False, fill_value='extrapolate')
        CF    = inter(np.log10(theta)) / theta
        return CF

    def _loadAsciiMean_CosmoSIS(self, stats, i, j, xArr, verbose=True):
        labConv = wtp.LabelConvention()
        
        if stats == labConv.w:
            name = '%sgalaxy_xi/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            yArr = loadAscii(name, verbose=verbose)
            theta = self.theta_nn
            w = self._interpolateCF(theta, xArr, yArr)
            return w
        
        if stats == labConv.gamma_t:
            name = '%sgalaxy_shear_xi/bin_%d_%d.txt' % (self.prefix_CosmoSIS, i+1, j+1)
            yArr = loadAscii(name, verbose=verbose)
            theta = self.theta_ne
            gamma_t = self._interpolateCF(theta, xArr, yArr)
            return gamma_t
          
        if stats == labConv.gamma_x:
            gamma_x = [0] * self.N_theta
            return gamma_x
        
        if stats == labConv.xi_p:
            name = '%sxi_binned_plus/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            xi_p = loadAscii(name, verbose=verbose)
            return xi_p
          
        if stats == labConv.xi_m:
            name = '%sxi_binned_minus/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            xi_m = loadAscii(name, verbose=verbose)
            return xi_m
          
        if stats == labConv.P_nn:
            name = '%sbandpower_galaxy/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            P_nn = loadAscii(name, verbose=verbose)
            return P_nn
        
        if stats == labConv.P_ne_E:
            name = '%sbandpower_galaxy_shear/bin_%d_%d.txt' % (self.prefix_CosmoSIS, i+1, j+1)
            P_ne_E = loadAscii(name, verbose=verbose)
            return P_ne_E
        
        if stats == labConv.P_ne_B:
            P_ne_B = [0] * self.N_ell_ne
            return P_ne_B
        
        if stats == labConv.P_ee_E:
            name   = '%sbandpower_shear_e/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            P_ee_E = loadAscii(name, verbose=verbose)
            return P_ee_E
          
        if stats == labConv.P_ee_B:
            P_ee_B = [0] * self.N_ell_ee
            return P_ee_B
          
        if stats == labConv.E_n:
            name = '%scosebis/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            E_n  = loadAscii(name, verbose=verbose)
            return E_n
        
        if stats == labConv.B_n:
            B_n = [0] * self.nbModes_ee
            return B_n

        if stats == labConv.Psi_gm:
            name = '%psi_stats_gm/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            Psi_gm  = loadAscii(name, verbose=verbose)
            return Psi_gm
            
        if stats == labConv.Psi_gg:
            name = '%spsi_stats_gg/bin_%d_%d.txt' % (self.prefix_CosmoSIS, j+1, i+1)
            Psi_gg  = loadAscii(name, verbose=verbose)
            return Psi_gg
        
        return None
    
    def _makeMean_CosmoSIS(self, statsTag, verbose=True):
        labConv = wtp.LabelConvention()
        tomoAngDict = self.makeTomoAngDict()
        statsList = statsTag.split('+')
        statsList_complete = tomoAngDict.keys()
        
        for stats in statsList:
            if stats not in statsList_complete:
                raise ValueError('\"%s\" not allowed' % statsTag)
        
        name  = '%sshear_xi_plus/theta.txt' % self.prefix_CosmoSIS
        xArr  = loadAscii(name, verbose=verbose) * (60.0 * 180.0 / np.pi) ## [arcmin]
        stock = []
        
        for stats, line in tomoAngDict.items():
            pairList = line[0]
          
            if stats in statsList:
                for i, j in pairList:
                    value = self._loadAsciiMean_CosmoSIS(stats, i, j, xArr, verbose=verbose)
                    stock.append(value)
        
        stock = np.concatenate(stock)
        return stock
    
    def setMean(self, tag, name=None, statsTag=None, verbose=True):
        if tag is None or tag == 'none':
            if statsTag == None:
                print('No mean')
                return None
        
            self.mean = self._makeMean_none(statsTag)
            print('Set mean to dummy values')
            return
        elif tag == 'Flinc':
            self.mean = self._makeMean_Flinc(name, statsTag, verbose=verbose) ## Consider `name` as `aves`
        elif tag == 'CosmoSIS':
            self.mean = self._makeMean_CosmoSIS(statsTag, verbose=verbose)
        elif tag == 'variable':
            self.mean = name ## Consider `name` as the variable which contains the mean
        
        ## Otherwise, consider `name` as the path to the file
        ## which contains the mean data vector
        else:
            try:
                if name[-4:] == '.npy':
                    self.mean = np.load(name).flatten()
                elif name[-4:] == '.fit' or name[-5:] == '.fits':
                    self.mean = fits.getdata(name, 1).field(0)
                else:
                    self.mean = np.loadtxt(name).flatten()
                if verbose:
                    print('Loaded \"%s\"' % name)
            except:
                raise OSError('\"%s\" not found' % name)
        return
    
    ## Covariance
    def _makeCov_Flinc(self, aves, statsTag, verbose=True):
        data = self._loadNpyDataMat_Flinc(aves, statsTag, 'obs', verbose=verbose)
        cov  = np.cov(data, rowvar=0, ddof=1)
        return cov
    
    def _makePairIndex_2PCF(self, tomo1, tomo2, sign, order=-1):
        if order > 0:
            beginGG = 0
            beginNG = self.__nbPairsGG * 2
            beginNN = self.__nbPairsGG * 2 + self.__nbPairsNG
            split   = self.nbTomoG
            tomo1G  = tomo1 - 0
            tomo1N  = tomo1 - split
            tomo2G  = tomo2 - 0
            tomo2N  = tomo2 - split
            
            isGG    = asInt(tomo2 < split)
            isNG    = asInt((tomo1 < split) * (tomo2 >= split))
            isNN    = asInt(tomo1 >= split)
            ind     = isGG * (beginGG + pairIndex(self.nbTomoG, tomo1G, tomo2G) + self.__nbPairsGG * sign)
            ind    += isNG * (beginNG + tomo2N + self.nbTomoN * tomo1G) ## Vary lens tomo bins first
            ind    += isNN * (beginNN + pairIndex(self.nbTomoN, tomo1N, tomo2N))
          
        else:
            beginNN = 0
            beginNG = self.__nbPairsNN
            beginGG = self.__nbPairsNN + self.__nbPairsNG
            split   = self.nbTomoN
            tomo1N  = tomo1 - 0
            tomo1G  = tomo1 - split
            tomo2N  = tomo2 - 0
            tomo2G  = tomo2 - split
            
            isNN    = asInt(tomo2 < split)
            isNG    = asInt((tomo1 < split) * (tomo2 >= split))
            isGG    = asInt(tomo1 >= split)
          
        ind  = isNN * (beginNN + pairIndex(self.nbTomoN, tomo1N, tomo2N))
        ind += isNG * (beginNG + tomo2G + self.nbTomoG * tomo1N) ## Vary source tomo bins first
        ind += isGG * (beginGG + pairIndex(self.nbTomoG, tomo1G, tomo2G) + self.__nbPairsGG * sign)
        return ind
    
    def _makePairIndex_BP(self, tomo1, tomo2, order=-1):
        if order > 0:
            beginGG = 0
            beginNG = self.__nbPairsGG
            beginNN = self.__nbPairsGG + self.__nbPairsNG
            split   = self.nbTomoG
            tomo1G  = tomo1 - 0
            tomo1N  = tomo1 - split
            tomo2G  = tomo2 - 0
            tomo2N  = tomo2 - split
            
            isGG    = asInt(tomo2 < split)
            isNG    = asInt((tomo1 < split) * (tomo2 >= split))
            isNN    = asInt(tomo1 >= split)
            ind     = isGG * (beginGG + pairIndex(self.nbTomoG, tomo1G, tomo2G))
            ind    += isNG * (beginNG + tomo2N + self.nbTomoN * tomo1G) ## Vary lens tomo bins first
            ind    += isNN * (beginNN + pairIndex(self.nbTomoN, tomo1N, tomo2N))
          
        else:
            beginNN = 0
            beginNG = self.__nbPairsNN
            beginGG = self.__nbPairsNN + self.__nbPairsNG
            split   = self.nbTomoN
            tomo1N  = tomo1 - 0
            tomo1G  = tomo1 - split
            tomo2N  = tomo2 - 0
            tomo2G  = tomo2 - split
            
            isNN    = asInt(tomo2 < split)
            isNG    = asInt((tomo1 < split) * (tomo2 >= split))
            isGG    = asInt(tomo1 >= split)
            
        ind  = isNN * (beginNN + pairIndex(self.nbTomoN, tomo1N, tomo2N))
        ind += isNG * (beginNG + tomo2G + self.nbTomoG * tomo1N) ## Vary source tomo bins first
        ind += isGG * (beginGG + pairIndex(self.nbTomoG, tomo1G, tomo2G))
        return ind
        
    """
    def _covListToMatrix_2PCF(self, data, cleanNaN=True, CTag='tot'):
        if cleanNaN:
            ind = np.isnan(data)
            data[ind] = 0.0
        
        tomoA1 = asInt(data[0]) - 1
        tomoA2 = asInt(data[1]) - 1
        tomoB1 = asInt(data[6]) - 1
        tomoB2 = asInt(data[7]) - 1
        signA  = asInt(data[4])
        signB  = asInt(data[10])
        binA   = asInt(data[5])
        binB   = asInt(data[11])
        if CTag == 'tot':
            value = data[12:].sum(axis=0)
        elif CTag == 'CNG2':
            value = data[12] + data[13] + data[14]
        elif CTag == 'CNG':
            value = data[12] + data[13]
        else:
            value = data[12]
        
        ## Make index
        indA  = self._makePairIndex_2PCF(tomoA1, tomoA2, signA, order=-1)
        indB  = self._makePairIndex_2PCF(tomoB1, tomoB2, signB, order=-1)
        indA  = binA + self.N_theta * indA
        indB  = binB + self.N_theta * indB
        d_tot = indA.max() + 1
        
        ## Fill the other triangle
        cov = np.zeros((d_tot, d_tot), dtype=float)
        cov[indA, indB] = value
        ind = np.arange(d_tot, dtype=int)
        cov[ind, ind] *= 0.5
        cov += cov.T
        return cov
    
    def _covListToMatrix_BP(self, data, cleanNaN=True, CTag='tot'):
        if cleanNaN:
            ind = np.isnan(data)
            data[ind] = 0.0
        
        tomoA1 = asInt(data[0]) - 1
        tomoA2 = asInt(data[1]) - 1
        tomoB1 = asInt(data[5]) - 1
        tomoB2 = asInt(data[6]) - 1
        binA   = asInt(data[4])
        binB   = asInt(data[9])
        if CTag == 'tot':
            value = data[10:].sum(axis=0)
        else:
            value = data[10]
        
        ## Make index
        indA  = self._makePairIndex_BP(tomoA1, tomoA2, order=-1)
        indB  = self._makePairIndex_BP(tomoB1, tomoB2, order=-1)
        indA  = binA + self.N_ell * indA
        indB  = binB + self.N_ell * indB
        d_tot = indA.max() + 1
        
        ## Fill the other triangle
        cov = np.zeros((d_tot, d_tot), dtype=float)
        cov[indA, indB] = value
        ind = np.arange(d_tot, dtype=int)
        cov[ind, ind] *= 0.5
        cov += cov.T
        return cov
    """
    
    def _get2PCFIndexForCut(self, statsTag):
        labConv = wtp.LabelConvention()
        wTh = True if labConv.w in statsTag else False
        gT  = True if labConv.gamma_t  in statsTag else False
        xiP = True if labConv.xi_p in statsTag else False
        xiM = True if labConv.xi_m in statsTag else False
        onept = True if labConv.onept in statsTag else False
        if onept:
            nobsbins = len(self.nobs[0].nobs[0])
        ind = [wTh]*self.N_theta_nn*self.__nbPairsNN + [gT]*self.N_theta_ne*self.__nbPairsNG + [xiP]*self.N_theta_ee*self.__nbPairsGG + [xiM]*self.N_theta_ee*self.__nbPairsGG + [onept]*nobsbins*self.__nbPairsONEPT
        return ind
    
    def _getBPIndexForCut(self, statsTag):
        labConv = wtp.LabelConvention()
        statsList = statsTag.split('+')
        Pnn  = True if labConv.P_nn in statsTag else False
        PneE = True if labConv.P_ne_E in statsTag else False
        PneB = True if labConv.P_ne_B in statsTag else False
        PeeE = True if labConv.P_ee_E in statsTag else False
        PeeB = True if labConv.P_ee_B in statsTag else False
        onept = True if labConv.onept in statsTag else False
        if onept:
            nobsbins = len(self.nobs[0].nobs[0])
        if PneE or PeeE == True:
            ind = [Pnn]*self.N_ell_nn*self.__nbPairsNN + [PneE]*self.N_ell_ne*self.__nbPairsNG + [PeeE]*self.N_ell_ee*self.__nbPairsGG + [onept]*nobsbins*self.__nbPairsONEPT
        else:
            ind = [Pnn]*self.N_ell_nn*self.__nbPairsNN + [PneB]*self.N_ell_ne*self.__nbPairsNG + [PeeB]*self.N_ell_ee*self.__nbPairsGG + [onept]*nobsbins*self.__nbPairsONEPT
        return ind
    
    def _getCOSEBIIndexForCut(self, statsTag):
        labConv = wtp.LabelConvention()
        En  = True if labConv.E_n in statsTag else False
        Bn  = True if labConv.B_n in statsTag else False
        Psi_gm = True if labConv.Psi_gm in statsTag else False
        Psi_gg = True if labConv.Psi_gg in statsTag else False
        onept = True if labConv.onept in statsTag else False
        if onept:
            nobsbins = len(self.nobs[0].nobs[0])
        ind = [Psi_gg]*self.nbModes_nn*self.__nbPairsNN + [Psi_gm]*self.nbModes_ne*self.__nbPairsNG + [En]*self.nbModes_ee*self.__nbPairsGG + [Bn]*self.nbModes_ee*self.__nbPairsGG + [onept]*nobsbins*self.__nbPairsONEPT
        return ind
    
    """
    @classmethod
    def getCategory(cls, statsTag):
        labConv = wtp.LabelConvention()
        statsList = statsTag.split('+')
        is2PCF    = False
        isBPE     = False
        isBPB     = False
        isCOSEBI  = False
        
        for stats in statsList:
            if stats in [labConv.w, labConv.gamma_t, labConv.gamma_x, labConv.xi_p, labConv.xi_m]:
                is2PCF   = is2PCF or True
            elif stats in [labConv.P_ne_E, labConv.P_ee_E]:
                isBPE    = isBPE or True
            elif stats in [labConv.P_ne_B, labConv.P_ee_B]:
                isBPB    = isBPB or True
            elif stats in [labConv.E_n, labConv.B_n]:
                isCOSEBI = isCOSEBI or True
        
        category = 1*int(is2PCF) + 2*int(isBPE) + 4*int(isBPB) + 8*int(isCOSEBI)
        return category

    def _makeCov_list(self, name, statsTag, cleanNaN=True, CTag='tot', verbose=True):
        covList  = loadAscii(name, verbose=verbose)
        category = TwoPointBuilder.getCategory(statsTag)
        
        if category == 1:
            cov = self._covListToMatrix_2PCF(covList, cleanNaN=cleanNaN, CTag=CTag)
            ind = self._get2PCFIndexForCut(statsTag)
        elif category in [0, 2, 4]:
            cov = self._covListToMatrix_BP(covList, cleanNaN=cleanNaN, CTag=CTag)
            ind = self._getBPIndexForCut(statsTag)
        elif category == 8:
            raise NotImplementedError('Reading COSEBI cov from list format not implemented')
        else:
            raise ValueError('statsTag = \"%s\" not allowed' % statsTag)
        
        cov = cov[ind].T[ind].T
        return cov
    """
    
    def _getIndexForCut_OneCov(self, statsTag):
        labConv = wtp.LabelConvention()
        statsTag = statsTag.split('+')
        
        ind = []
        for stat in statsTag:
            if self.nbTomoN > 0:
                wTh = True if labConv.w == stat else False
                Pnn  = True if labConv.P_nn == stat else False
                Psi_gg = True if labConv.Psi_gg == stat else False
                if wTh:
                    if not self.smbinAuto:
                        ind_nn = []
                        for i in range(self.nbTomoN):
                            for j in range(i, self.nbTomoN):
                                if self.nnAuto:
                                    if i==j:
                                        ind_nn += [True]*self.N_theta_nn
                                    else:
                                        ind_nn += [False]*self.N_theta_nn
                                else:
                                    ind_nn += [True]*self.N_theta_nn
                        ind += ind_nn
                    else:
                        ind += [wTh]*self.N_theta_nn*self.__nbPairsNN
                if Pnn:
                    if not self.smbinAuto:
                        ind_nn = []
                        for i in range(self.nbTomoN):
                            for j in range(i, self.nbTomoN):
                                if self.nnAuto:
                                    if i==j:
                                        ind_nn += [True]*self.N_ell_nn
                                    else:
                                        ind_nn += [False]*self.N_ell_nn
                                else:
                                    ind_nn += [True]*self.N_ell_nn
                        ind += ind_nn
                    else:
                        ind += [Pnn]*self.N_ell_nn*self.__nbPairsNN
                if Psi_gg:
                    if not self.smbinAuto:
                        ind_nn = []
                        for i in range(self.nbTomoN):
                            for j in range(i, self.nbTomoN):
                                if self.nnAuto:
                                    if i==j:
                                        ind_nn += [True]*self.nbModes_nn
                                    else:
                                        ind_nn += [False]*self.nbModes_nn
                                else:
                                    ind_nn += [True]*self.nbModes_nn
                        ind += ind_nn
                    else:
                        ind += [Psi_gg]*self.nbModes_nn*self.__nbPairsNN
        
            if self.nbTomoN > 0 and self.nbTomoG > 0:
                gT  = True if labConv.gamma_t == stat else False
                PneE = True if labConv.P_ne_E == stat else False
                PneB = True if labConv.P_ne_B == stat else False
                Psi_gm = True if labConv.Psi_gm == stat else False
                if gT:
                    ind += [gT]*self.N_theta_ne*self.__nbPairsNG
                if PneE:
                    ind += [PneE]*self.N_ell_ne*self.__nbPairsNG
                if PneB:
                    ind += [PneB]*self.N_ell_ne*self.__nbPairsNG
                if Psi_gm:
                    ind += [Psi_gm]*self.nbModes_ne*self.__nbPairsNG
        
            if self.nbTomoG > 0:
                xiP = True if labConv.xi_p == stat else False
                xiM = True if labConv.xi_m == stat else False
                PeeE = True if labConv.P_ee_E == stat else False
                PeeB = True if labConv.P_ee_B == stat else False
                En  = True if labConv.E_n == stat else False
                Bn  = True if labConv.B_n == stat else False
                if xiP:
                    ind += [xiP]*self.N_theta_ee*self.__nbPairsGG
                if xiM:
                    ind += [xiM]*self.N_theta_ee*self.__nbPairsGG
                if PeeE:
                    ind += [PeeE]*self.N_ell_ee*self.__nbPairsGG
                if PeeB:
                    ind += [PeeB]*self.N_ell_ee*self.__nbPairsGG
                if En:
                    ind += [En]*self.nbModes_ee*self.__nbPairsGG
                if Bn:
                    ind += [Bn]*self.nbModes_ee*self.__nbPairsGG
        
            if self.nbObs > 0:
                onept = True if labConv.onept == stat else False
                if onept:
                    nobsbins = len(self.nobs[0].nobs[0])
                    ind += [onept]*nobsbins*self.__nbPairsONEPT
        return ind
       
    
    def _makeCov_OneCov(self, name, statsTag, cleanNaN=True, CTag='tot', verbose=True):
        cov  = np.genfromtxt(name)
        ind = self._getIndexForCut_OneCov(statsTag)
        cov = cov[ind].T[ind].T
        return cov
    
    
    def setCov(self, tag, name=None, statsTag=None, cleanNaN=True, CTag='tot', verbose=True):
        if tag is None or tag == 'none':
            print('No covariance')
            return
        elif tag == 'Flinc':
            self.cov = self._makeCov_Flinc(name, statsTag, verbose=verbose) ## Consider `name` as `aves`
        elif tag == 'list':
            self.cov = self._makeCov_list(name, statsTag, cleanNaN=cleanNaN, CTag=CTag, verbose=verbose)
        elif tag == 'onecov':
            self.cov = self._makeCov_OneCov(name, statsTag, cleanNaN=cleanNaN, CTag=CTag, verbose=verbose)
        elif tag == 'variable':
            self.cov = name ## Consider `name` as the variable which contains the covariance
      
        ## Otherwise, consider `name` as the path to the file
        ## which contains the covariance matrix
        else:
            try:
                if name[-4:] == '.npy':
                    self.cov = np.load(name)
                elif name[-4:] == '.fit' or name[-5:] == '.fits':
                    self.cov = fits.getdata(name, 1)
                else:
                    self.cov = np.loadtxt(name)
                if verbose:
                    print('Loaded \"%s\"' % name)
            except:
                raise OSError('\"%s\" not found' % name)
        return
    
    ## 1pt
    def _make1pt(self, name, nobsNameList):
        if isinstance(nobsNameList, list):
            pass
        else:
            nobsNameList = [nobsNameList]
        if len(nobsNameList) == 0:
            return None
        
        nobsName = nobsNameList[0]
        if nobsName[-4:] == '.npy':
            nobsList = [np.load(nobsName) for nobsName in nobsNameList]
        elif nobsName[-4:] == '.fit' or nobsName[-5:] == '.fits':
            nobsList = [fits.getdata(nobsName, 1) for nobsName in nobsNameList]
            nobsList = [[data.field(0), data.field(1)] for data in nobsList]
        else:
            nobsList = [loadAscii(nobsName, verbose=self.verbose) for nobsName in nobsNameList]
        
        obsArr   = [nobs[0] for nobs in nobsList]
        nobsList = [nobs[1] for nobs in nobsList]
        obs_low = []
        obs_high = []
        obs_middle = []
        for xobs in obsArr:
            #d_obs = np.log10(xobs[1]) - np.log10(xobs[0])
            #obs_low.append(10.0**(np.log10(xobs) - 0.5 * d_obs))
            #obs_high.append(10.0**(np.log10(xobs) + 0.5 * d_obs))
            obs_middle.append(xobs)
        if obs_low == []:
            obs_low = None
        if obs_high == []:
            obs_high = None
        nobs = twopoint.OnePointMeasurement(name, obs_middle, nobsList, obs_low, obs_high)
        return nobs
     
    def setNobs(self, tag, name=None, statsTag=None, cleanNaN=True, CTag='tot', verbose=True):
        if tag is None or tag == 'none':
            print('No observable function')
            return
        elif tag == 'variable':
            self.nobs = name ## Consider `name` as the variable which contains the covariance
      
        ## Otherwise, consider `name` as the path to the file
        ## which contains the covariance matrix
        else:
            labConv = wtp.LabelConvention()
            nobs = self._make1pt(labConv.onept, name)
            self.nobs = [nobs]
        return
    
    ## n(z)
    def _makeKernel(self, name, nOfZNameList, nGalList, sigmaEpsList):
        if len(nOfZNameList) == 0:
            return None
        
        nOfZName = nOfZNameList[0]
        if nOfZName[-4:] == '.npy':
            nOfZList = [np.load(nOfZName) for nOfZName in nOfZNameList]
        elif nOfZName[-4:] == '.fit' or nOfZName[-5:] == '.fits':
            nOfZList = [fits.getdata(nOfZName, 1) for nOfZName in nOfZNameList]
            nOfZList = [[data.field(0), data.field(1)] for data in nOfZList]
        else:
            nOfZList = [loadAscii(nOfZName, verbose=self.verbose) for nOfZName in nOfZNameList]
        
        zArr     = nOfZList[0][0]
        nOfZList = [nOfZ[1][:-1] for nOfZ in nOfZList]
        z_lower  = zArr[:-1]
        z_upper  = zArr[1:]
        z_middle = 0.5 * (z_lower + z_upper)
        kernel   = twopoint.NumberDensity(name, z_lower, z_middle, z_upper, nOfZList, ngal=nGalList, sigma_e=sigmaEpsList)
        return kernel
      
    def setNOfZ(self, nOfZNameList, nGalList=None, sigmaEpsList=None):
        if nOfZNameList is None or nOfZNameList == 'none':
            print('No n(z)')
            return
        
        nbTomo = self.nbTomoN + self.nbTomoG + self.nbObs
        
        ## Assert
        if nbTomo == len(nOfZNameList):
            nOfZNameListN = nOfZNameList[:self.nbTomoN]
            nOfZNameListG = nOfZNameList[self.nbTomoN:self.nbTomoG+self.nbTomoN]
            nOfZNameListO = nOfZNameList[self.nbTomoG+self.nbTomoN:]
        else:
            raise AssertionError('Bad length of nOfZNameList')
        
        ## Assert
        if nGalList is None:
            nGalListN = None
            nGalListG = None
            nGalListO = None
        elif nbTomo == len(nGalList):
            nGalListN = nGalList[:self.nbTomoN]
            nGalListG = nGalList[self.nbTomoN:self.nbTomoG+self.nbTomoN]
            nGalListO = nGalList[self.nbTomoG+self.nbTomoN:]
        else:
            raise AssertionError('Bad length of nGalList')
        
        ## Assert
        if sigmaEpsList is None:
            pass
        elif len(sigmaEpsList) == self.nbTomoG:
            pass
        elif len(sigmaEpsList) == nbTomo:
            sigmaEpsList = sigmaEpsList[self.nbTomoN:]
        else:
            raise AssertionError('Bad length of sigmaEpsList')
        
        ## Make
        labConv = wtp.LabelConvention()
        kernelN = self._makeKernel(labConv.lens, nOfZNameListN, nGalListN, None)
        kernelG = self._makeKernel(labConv.source, nOfZNameListG, nGalListG, sigmaEpsList)
        kernelO = self._makeKernel(labConv.obs, nOfZNameListO, nGalListO, None)
        kernelList = [kernelN, kernelG, kernelO]
        
        self.kernelList = [kern for kern in kernelList if kern is not None]
        """
        if kernelN is None:
            self.kernelList = [kernelG]
        elif kernelG is None:
            self.kernelList = [kernelN]
        else:
            self.kernelList = [kernelN, kernelG]
        """
        return
    
    ## Build up & save
    def _makeTwoPoint_withCov(self, labConv, statsTag_c):
        tomoAngDict = self.makeTomoAngDict()
        statsList_c  = statsTag_c.split('+')
        statsList_c_complete = list(labConv.kernelTypeDict.keys())
        statsList_c_complete.append(labConv.onept)
      
        for stats_c in statsList_c:
            if stats_c not in statsList_c_complete:
                raise ValueError('\"%s\" not allowed' % statsTag_c)
    
        statsNameDict = {}
        scBuilder = twopoint.SpectrumCovarianceBuilder()
        binInd    = 0
      
        for stats_c, line1, line2 in zip(labConv.kernelTypeDict.keys(), labConv.kernelTypeDict.values(), tomoAngDict.values()):
            ker1, ker2, type1, type2, unit = line1
            pairList, N_ang, angle         = line2
            
            if stats_c in statsList_c:
                statsNameDict[(ker1, ker2, type1, type2)] = stats_c
                for i, j in pairList:
                    for angInd in range(N_ang):
                        x = angle[angInd]
                        y = self.mean[binInd]
                        binInd += 1
                        scBuilder.add_data_point(ker1, ker2, type1, type2, i+1, j+1, x, angInd+1, y)
        
        if self.nobs is not None:
            for obs in self.nobs:
                if obs.name in statsList_c:
                    for i in range(obs.nbin):
                        for angInd in range(obs.nsample[i]):
                            x = obs.obs[i][angInd]
                            y = obs.nobs[i][angInd]
                            binInd += 1
                            scBuilder.add_one_point(obs.name, i+1, x, angInd+1, y)
                
      
        ## Make TP
        scBuilder.set_names(statsNameDict)
        spectra, cov_info = scBuilder.generate(self.cov, 'arcmin')
        
        TP = wtp.TwoPointWrapper.from_spectra(spectra, kernels=self.kernelList, nobs=self.nobs, covmat_info=cov_info) ## kernels & covmat_info can be None
        return TP
    
    def _makeTwoPoint_withoutCov(self, labConv, statsTag_c):
        tomoAngDict = self.makeTomoAngDict()
        statsList_c  = statsTag_c.split('+')
        statsList_c_complete = list(labConv.kernelTypeDict.keys())
        statsList_c_complete.append(labConv.onept)
        
        for stats_c in statsList_c:
            if stats_c not in statsList_c_complete:
                raise ValueError('\"%s\" not allowed' % statsTag_c)
        
        spectra = []
        binInd  = 0
        
        for stats_c, line1, line2 in zip(labConv.kernelTypeDict.keys(), labConv.kernelTypeDict.values(), tomoAngDict.values()):
            ker1, ker2, type1, type2, unit = line1
            pairList, N_ang, angle         = line2
            
            if stats_c in statsList_c:
                sBuilder = wtp.SpectrumBuilder()
              
                for i, j in pairList:
                    value   = self.mean[binInd:binInd+N_ang]
                    binInd += N_ang
                    sBuilder.addTomo(i, j, angle, value)
          
                spec = sBuilder.makeSpectrum(stats_c, (type1, type2), unit, kernels=(ker1, ker2)) ## kernels can be None
                spectra.append(spec)
        
        if self.nobs is not None:
            for obs in self.nobs:
                if obs.name in statsList_c:
                    for i in range(obs.nbin):
                        for angInd in range(obs.nsample[i]):
                            x = obs.obs[i][angInd]
                            y = obs.nobs[i][angInd]
                            binInd += 1
                            sBuilder.add_one_point(obs.name, i+1, x, angInd+1, y)
        
        ## Make
        TP = wtp.TwoPointWrapper.from_spectra(spectra, kernels=self.kernelList, nobs=self.nobs, covmat_info=None) ## kernels & covmat_info can be None
        return TP
    
    def _makeTwoPoint_onlyNOfZ(self):
        TP = wtp.TwoPointWrapper.from_spectra([], kernels=self.kernelList, nobs=None, covmat_info=None) ## spectra = [], kernels & covmat_info can be None
        return TP
    
    def makeTwoPoint(self, labConv, statsTag_c):
        if self.mean is None and self.cov is None:
          TP = self._makeTwoPoint_onlyNOfZ()
        elif self.cov is None:
          TP = self._makeTwoPoint_withoutCov(labConv, statsTag_c)
        else:
          TP = self._makeTwoPoint_withCov(labConv, statsTag_c)
        return TP
    
    @classmethod
    def addCovToTwoPoint(cls, TP, statsList, dimList, cov):
        cov_info = twopoint.CovarianceMatrixInfo('COVMAT', statsList, dimList, cov)
        TP2 = wtp.TwoPointWrapper.from_spectra(TP.spectra, kernels=TP.kernels, covmat_info=cov_info)
        return TP2
        
###############################################################################
## Auxiliary functions

def loadAscii(name, sep=None, cmt='#', verbose=True):
    data = np.loadtxt(name, comments=cmt, delimiter=sep)
    if verbose is True:
        print('Loaded \"%s\"' % name)
    return data.T

def asInt(a, copy=True):
    if np.isscalar(a):
        return int(a)
    if type(a) is list:
        return np.array(a, dtype=int)
    return a.astype(int, copy=copy)
  
def pairIndex(N, i, j):
    ind  = (N + (N+1-i)) * i // 2
    ind += j - i
    return ind

def getPrefix():
  return 'data/KiDS/kcap/Input_mean_cov_nOfZ/'

###############################################################################
## Main function snippet

def saveFitsTwoPoint(
        nbTomoN=0,
        nbTomoG=0,
        nbObs=0,
        N_theta_ee=12,
        theta_min_ee=0.5,
        theta_max_ee=300,
        N_ell_ee=8,
        ell_min_ee=100,
        ell_max_ee=1500,
        nbModes_ee=5,
        N_theta_ne=12,
        theta_min_ne=0.5,
        theta_max_ne=300,
        N_ell_ne=8,
        ell_min_ne=100,
        ell_max_ne=1500,
        nbModes_ne=5,
        N_theta_nn=12,
        theta_min_nn=0.5,
        theta_max_nn=300,
        N_ell_nn=8,
        ell_min_nn=100,
        ell_max_nn=1500,
        nbModes_nn=5,
        nnAuto=False,
        smbinAuto=True,
        prefix_Flinc=None,
        prefix_CosmoSIS=None,
        scDict={},
        meanTag=None, meanName=None,
        covTag=None, covName=None,
        nobsTag=None, nobsName=None,
        nOfZNameList=None, nGalList=None, sigmaEpsList=None,
        saveName=None
    ):
    
    labConv = wtp.LabelConvention()
    
    ## Custom
    TPBuilder = TwoPointBuilder(
        nbTomoN=nbTomoN,
        nbTomoG=nbTomoG,
        nbObs=nbObs,
        N_theta_ee=N_theta_ee,
        theta_min_ee=theta_min_ee,
        theta_max_ee=theta_max_ee,
        N_ell_Ee=N_ell_ee,
        ell_min_ee=ell_min_ee,
        ell_max_ee=ell_max_ee,
        nbModes_ee=nbModes_ee,
        N_theta_ne=N_theta_ne,
        theta_min_ne=theta_min_ne,
        theta_max_ne=theta_max_ne,
        N_ell_ne=N_ell_ne,
        ell_min_ne=ell_min_ne,
        ell_max_ne=ell_max_ne,
        nbModes_ne=nbModes_ne,
        N_theta_nn=N_theta_nn,
        theta_min_nn=theta_min_nn,
        theta_max_nn=theta_max_nn,
        N_ell_nn=N_ell_nn,
        ell_min_nn=ell_min_nn,
        ell_max_nn=ell_max_nn,
        nbModes_nn=nbModes_nn,
        nnAuto=nnAuto,
        smbinAuto=smbinAuto,
        prefix_Flinc=prefix_Flinc,
        prefix_CosmoSIS=prefix_CosmoSIS
    )
    
    ## Labels
    statsList, scArgs = labConv.makeScaleCutsArgs(scDict)
    if statsList is not None:
        statsTag_c = labConv.defaultToCustomStatsTag('+'.join(statsList))
        statsTag   = labConv.customToDefaultStatsTag(statsTag_c)
    else:
        statsTag_c = None
        statsTag   = None
        
    ## Make
    TPBuilder.setMean(meanTag, name=meanName, statsTag=statsTag)
    TPBuilder.setNobs(nobsTag, name=nobsName)
    TPBuilder.setCov(covTag, name=covName, statsTag=statsTag)
    TPBuilder.setNOfZ(nOfZNameList, nGalList=nGalList, sigmaEpsList=sigmaEpsList)
    TP = TPBuilder.makeTwoPoint(labConv, statsTag_c)
    
    ## Cut
    TP.cutScales(cutCross=scArgs[0], statsTag_tomoInd_tomoInd_list=scArgs[1], statsTag_binIndList_dict=scArgs[2])
    TP.keepScales(statsTag_tomoInd1_tomoInd2__angMin_angMax_dict=scArgs[3], statsTag__angMin_angMax_dict=scArgs[4])
    
    ## Save
    TP.to_fits(saveName, overwrite=True, clobber=True)
    print('Saved \"%s\"' % saveName)
    return

def printUnitaryTest():
    name1 = initialize()
    #name2 = initialize()
    name2 = '%stwoPoint_xiPM_mean_KV450Data_cov_KV450_nofz_KV450Data.fits' % getPrefix()
    unitaryTest(name1, name2)
    return
    
###############################################################################

