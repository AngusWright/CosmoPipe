#!/bin/bash
# wrapper script for KiDS-1000 joint covariance calculation


### settings

# cosmology
omf=0.3099 #0.3125 #0.2905
ovf=0.6901 #0.6875 #0.7095     
sif=0.7567 #0.7307 #0.8260
huf=0.7215 #0.7000 #0.6898
nsf=0.8701 #0.9700 #0.9690
obf=0.0487 #0.0459 #0.0473
w0f=-1.00
waf=0.00
aia=1.0223 #0.80    # IA amplitude

ZBLIMS="@TOMOLIMS@"
NTOMO=`echo @TOMOLIMS@ | awk '{print NF-1}'`

# binnings
nz_fg=2         # no. of fg redshift bins
nz_bg=@NTOMOBINS@          # no. of bg redshift bins
nt_xi=@NTHETABINCOV@   # no. of angular bins (direct corr. fct covariance)
tbmin_xi=@THETAMINCOV@    # min. angular bin boundary [arcmin]
tbmax_xi=@THETAMAXCOV@   # max. angular bin boundary [arcmin]
nt_bp=@NTHETABINXI@      # no. of angular bins (for band power calculations)
tbmin_bp=@THETAMINXI@    # min. angular bin boundary [arcmin]
tbmax_bp=@THETAMAXXI@    # max. angular bin boundary [arcmin] 
tcutmin=0.5     # min. angular scale to be used in bandpower conversion  [arcmin]
tcutmax=300.    # max. angular scale to be used in bandpower conversion  [arcmin]
nbp=8           # no. of bandpower bins
bpmin=100.      # min. angular bandpower frequency 
bpmax=1500.     # max. angular bandpower frequency 
apod_width=0.5  # log width of apodisation window [total width of apodised range is tmax/tmin=exp(width); <0 for no apodisation]

### files and paths
##blind=C   # A B C 
##machine=barra
##run_ident=kids1000_blind${blind}_bp_iterated
##repo_path=/export/${machine}/joachimi/kids/kids1000/Cat_to_Obs_K1000_P1/data/kids/
##input_path=/export/${machine}/joachimi/kids/kids1000/cov_input/
##result_path=/export/${machine}/joachimi/kids/kids1000/cov_results/
##pofz_ident_lens=${repo_path}/../boss/nofz/BOSS_and_2dFLenS_n_of_z
##pofz_ident_source=${repo_path}/nofz/SOM_N_of_Z/K1000_NS_V1.0.0A_ugriZYJHKs_photoz_SG_mask_LF_svn_309c_2Dbins_v2_DIRcols_Fid_blind${blind}
##densfile_fg=${input_path}/ndens_kids1000_4096_fg.dat
##densfile=${repo_path}/number_density/ngal_blind${blind}.ascii
##epsfile=${repo_path}/ellipticity_dispersion/sigma_e_blind${blind}.ascii
##biasfile=${input_path}/galaxy_bias_iterated.dat  #galaxy_bias_troester.dat
##mask_file_lens=${input_path}/complex_lens_mask.fits
##mask_file_source=${input_path}/K1000_healpix_DR4.1_nside_4096.fits
##ext_ps_file=${input_path}/POfKAndA_buceros.dat
##npair_file=${repo_path}/number_of_galaxy_pairs/pairCounts_K1000_blind${blind}_Flag_SOM_Fid_NTheta326_nbTomo7.dat  #bp case
###npair_file=${repo_path}/number_of_galaxy_pairs/npair_blind${blind}_V1.0.0A_ugriZYJHKs_photoz_SG_mask_LF_svn_309c_2Dbins_v2_goldclasses_Flag_SOM_Fid_nTheta9.ascii  #xi case
# files and paths
blind=@BLIND@  
run_ident=@RUNID@
#repo_path=/export/${machine}/joachimi/kids/kids1000/Cat_to_Obs_K1000_P1/data/kids/
repo_path=@RUNROOT@/@STORAGEPATH@/
input_path=${repo_path}/covariance/input/
result_path=/${repo_path}/covariance/output/
pofz_ident_lens=${input_path}/../boss/nofz/BOSS_and_2dFLenS_n_of_z
pofz_ident_source=${input_path}/@NZFILEID@comb@NZFILESUFFIX
densfile_fg=${input_path}/ndens_kids1000_4096_fg.dat
densfile=${repo_path}/ngal_blind${blind}.ascii
epsfile=${repo_path}/sigma_e_blind${blind}.ascii
biasfile=${input_path}/galaxy_bias_iterated.dat  #galaxy_bias_troester.dat
mask_file_lens=${input_path}/complex_lens_mask.fits
mask_file_source=${repo_path}/@MASKFILE@
ext_ps_file=${input_path}/POfKAndA_buceros.dat
npair_file=${repo_path}/pairCounts_K1000_blind${blind}_Flag_SOM_Fid_NTheta326_nbTomo7.dat  #bp case

# covariance settings
do_cov=1       # 1: calculate covariance; 0: skip calculation
do_assembly=1  # 1: assemble full covariance; 0: skip calculation
do_bp=1        # 1: calculate bandpower covariance; 2: process individual terms; 0: skip calculation
noiseflag=0    # 0: full covariance; 1: diagonal only; 2: shape/shot noise only; 3: shear contributions nulled

use_mask=1   # 1: use mask from mask_file; 0: assume simple square mask
survey_area_lens=852.8459      # survey area in deg^2; only used if use_mask=0
survey_area_source=773.285946  # survey area in deg^2; only used if use_mask=0
use_ext_ps=1  # 1: use external PS in ext_ps_file; 0: internal PS model
use_actual_pairs=1   # 1: use actual galaxy pairs for shape/shot noise; 0: use expectation value

cov_ssc=1   # 1: include; 0: switch off
cov_ng=1
cov_g=1



### CODE ###

### internal settings
home=$PWD
repo_path=/home/joachimi/coderepo/
python_path=/usr/local/anaconda3/bin/
zfromfile=1
nz=`awk 'BEGIN{ print '${nz_fg}'+'${nz_bg}' }'`
binlist=""  # unused
transferfunc=EHW
hmf_type=T10
use_hod=0  # use effective linear bias
flag_2h=0 #1  #use 2h term in trispectrum
nl=1  # unused
lmin=1.  # unused
lmax=1.  # unused
zmin=0.  # min redshift used in n(z) 
zmax=4.  # max redshift used in n(z) 
nz_interp_step=0.01  # step size that n(z) are interpolated to
cov_space=1  # use real space covariance
printzpg=1
export THPS_LINLOG2=log        # enforce log binning
export THPS_COV_INVERSE=no    # calculate inverse
export THPS_BINAVERAGE=gauss  # angular bin averaging
export THPS_COV_IA=nla  # IA model in Gaussian terms

tmp=${mask_file_lens%.*}
mask_base_lens=${tmp##*/}
tmp=${mask_file_source%.*}
mask_base_source=${tmp##*/}

if [ $noiseflag -gt 1 ]  # force non-Gaussian terms to 0
then
  cov_ssc=0
  cov_ng=0
fi
if [ $noiseflag -eq 2 ]  # no mask needed for noise-only covariance
then
  use_mask=0
fi
if [ $use_ext_ps -eq 1 ]
then
  nonlinfit=EXT
else
  nonlinfit=TAK12
fi

if [ $do_bp -ge 1 ]
then  # band powers
  covtype=2
  nt=$nt_bp
  tbmin=$tbmin_bp
  tbmax=$tbmax_bp
else  # corr. functions
  covtype=1
  nt=$nt_xi
  tbmin=$tbmin_xi
  tbmax=$tbmax_xi
fi

if [[ "${npair_file}" != *"${nt}"* ]]
then
  echo "pair count file does not match requested type of covariance."
  exit -1
fi

### prepare n(z) files
echo "" > ${pofz_ident_source}_comb.dat

for ((i=1; i<=${nz_fg}; i++ ))
do
  ${python_path}/python interpolate_nz.py ${pofz_ident_lens}${i}_res_0.01.txt ${zmin} ${zmax} ${nz_interp_step}
  paste ${pofz_ident_source}_comb.dat ${pofz_ident_lens}${i}_res_0.01_interp.dat > tmp.dat
  mv tmp.dat ${pofz_ident_source}_comb.dat
done

for ((i=1; i<=${nz_bg}; i++ ))
do
  ${python_path}/python interpolate_nz.py ${pofz_ident_source}_TOMO${i}_Nz.asc ${zmin} ${zmax} ${nz_interp_step}
  paste ${pofz_ident_source}_comb.dat ${pofz_ident_source}_TOMO${i}_Nz_interp.dat > tmp.dat
  mv tmp.dat ${pofz_ident_source}_comb.dat
done

awk '{ printf "%15.10f\t", $1; for (i=2;i<=2*('${nz}');i+=2) printf "%15.10f\t", $i; printf "\n" }' ${pofz_ident_source}_comb.dat > tmp.dat
mv tmp.dat ${pofz_ident_source}_comb.dat

zfile=${pofz_ident_source}_comb.dat

### prepare n_dens and sigma_eps files

#awk '{ if ((NR>=1)&&(NR<='${nz_fg}')) print $1 }' $densfile > ${result_path}/thps_cov_${run_ident}_source_ndens_fg.dat
cp $densfile_fg ${result_path}/thps_cov_${run_ident}_source_ndens_fg.dat
cp ${result_path}/thps_cov_${run_ident}_source_ndens_fg.dat ${result_path}/thps_cov_${run_ident}_lens_ndens_fg.dat
cp ${result_path}/thps_cov_${run_ident}_source_ndens_fg.dat ${result_path}/thps_cov_${run_ident}_cross_ndens_fg.dat

#awk '{ if ((NR>'${nz_fg}')&&(NR<='${nz}')) print $1 }' $densfile > ${result_path}/thps_cov_${run_ident}_source_ndens.dat
awk '{ for (i=1;i<=NF;i++) print $i }' $densfile > ${result_path}/thps_cov_${run_ident}_source_ndens.dat
cp ${result_path}/thps_cov_${run_ident}_source_ndens.dat ${result_path}/thps_cov_${run_ident}_lens_ndens.dat
cp ${result_path}/thps_cov_${run_ident}_source_ndens.dat ${result_path}/thps_cov_${run_ident}_cross_ndens.dat

#awk '{ print $1*sqrt(2.) }' $epsfile > ${result_path}/thps_cov_${run_ident}_source_sigma_sq.dat
awk '{ for (i=1;i<=NF;i++) print $i*sqrt(2.) }' $epsfile > ${result_path}/thps_cov_${run_ident}_source_sigma_sq.dat
cp ${result_path}/thps_cov_${run_ident}_source_sigma_sq.dat ${result_path}/thps_cov_${run_ident}_lens_sigma_sq.dat
cp ${result_path}/thps_cov_${run_ident}_source_sigma_sq.dat ${result_path}/thps_cov_${run_ident}_cross_sigma_sq.dat


### prepare survey window files
if [ $use_mask -eq 1 ]
then

  if [ -s ${result_path}/survey_window_alm_${mask_base_source}.dat ]
  then
    echo "Re-use survey window alm file ${result_path}/survey_window_alm_${mask_base_source}.dat"
  else
    cd ${repo_path}/covariances/survey_window/

    ${python_path}/python survey_window.py ${mask_file_source} ${result_path}/survey_window_alm_${mask_base_source}.dat ${result_path}/survey_window_area_${mask_base_source}.dat
  fi

  area_source=`awk '{ if ($1!="#") print $1 }' ${result_path}/survey_window_area_${mask_base_source}.dat`
  echo "Use effective area for source survey:" $area_source

  cp ${result_path}/survey_window_alm_${mask_base_source}.dat ${result_path}/thps_cov_${run_ident}_source_alms.dat
  cp ${result_path}/survey_window_area_${mask_base_source}.dat ${result_path}/thps_cov_${run_ident}_source_alms_area.dat

else
  area_source=$survey_area_source
  echo "Use simple geometry with source survey area:" $area_source

  rm -f ${result_path}/thps_cov_${run_ident}_source_alms.dat ${result_path}/thps_cov_${run_ident}_source_alms_area.dat
fi


if [ $use_mask -eq 1 ]
then

  if [ $mask_base_lens != $mask_base_source ]
  then
    if [ -s ${result_path}/survey_window_alm_${mask_base_lens}.dat ]
    then
      echo "Re-use survey window alm file ${result_path}/survey_window_alm_${mask_base_lens}.dat"
    else
      cd ${repo_path}/covariances/survey_window/

      ${python_path}/python survey_window.py ${mask_file_lens} ${result_path}/survey_window_alm_${mask_base_lens}.dat ${result_path}/survey_window_area_${mask_base_lens}.dat
    fi
  fi

  area_lens=`awk '{ if ($1!="#") print $1 }' ${result_path}/survey_window_area_${mask_base_lens}.dat`
  echo "Use effective area for lens survey:" $area_lens

  cp ${result_path}/survey_window_alm_${mask_base_lens}.dat ${result_path}/thps_cov_${run_ident}_lens_alms.dat
  cp ${result_path}/survey_window_area_${mask_base_lens}.dat ${result_path}/thps_cov_${run_ident}_lens_alms_area.dat

else
  area_lens=$survey_area_lens
  echo "Use simple geometry with lens survey area:" $area_lens

  rm -f ${result_path}/thps_cov_${run_ident}_lens_alms.dat ${result_path}/thps_cov_${run_ident}_lens_alms_area.dat
fi


if [ $use_mask -eq 1 ]
then

  if [ -s ${result_path}/survey_window_alm_${mask_base_lens}_${mask_base_source}.dat ]
  then
    echo "Re-use survey window alm file ${result_path}/survey_window_alm_${mask_base_lens}_${mask_base_source}.dat"
  else
    cd ${repo_path}/covariances/survey_window/

    ${python_path}/python survey_window_cross.py ${mask_file_lens} ${mask_file_source} ${result_path}/survey_window_alm_${mask_base_lens}_${mask_base_source}.dat ${result_path}/survey_window_area_${mask_base_lens}_${mask_base_source}.dat
  fi

  cp ${result_path}/survey_window_alm_${mask_base_lens}_${mask_base_source}.dat ${result_path}/thps_cov_${run_ident}_cross_alms.dat
  cp ${result_path}/thps_cov_${run_ident}_source_alms_area.dat ${result_path}/thps_cov_${run_ident}_cross_alms_area.dat  # use source area here; then correct with lens area in post-processing

else
  area_cross=$survey_area_source

  rm -f ${result_path}/thps_cov_${run_ident}_cross_alms.dat ${result_path}/thps_cov_${run_ident}_cross_alms_area.dat
fi


cd $home


### prepare galaxy pair count files
if [ $use_actual_pairs -eq 1 ]
then
  cp ${npair_file} ${result_path}/thps_cov_${run_ident}_source_npair.dat  # in correct format
  cp ${npair_file} ${result_path}/thps_cov_${run_ident}_lens_npair.dat 
  cp ${npair_file} ${result_path}/thps_cov_${run_ident}_cross_npair.dat 
else
  rm -f ${result_path}/thps_cov_${run_ident}_source_npair.dat
  rm -f ${result_path}/thps_cov_${run_ident}_lens_npair.dat
  rm -f ${result_path}/thps_cov_${run_ident}_cross_npair.dat
fi



### create parameter files

cp ${repo_path}/psvareos/proc/thps.param ${result_path}/

awk '{
 if (/Omega_m/) print "Omega_m			'${omf}'"
 else if (/Omega_v/) print "Omega_v			'${ovf}'"
 else if (/w_0/) print "w_0            	    '${w0f}'"
 else if (/w_a/) print "w_a			     '${waf}'"
 else if (/Omega_b/) print "Omega_b			'${obf}'"
 else if (/h_100/) print "h_100			'${huf}'"
 else if (/sigma_8/) print "sigma_8			'${sif}'"
 else if (/n_spec/) print "n_spec			'${nsf}'"
 else if (/bg_zdistr_zmin/) print "bg_zdistr_zmin          '${zmin}'"
 else if (/bg_zdistr_zmax/) print "bg_zdistr_zmax         '${zmax}'"
 else if (/bg_zdistr_file/) print "bg_zdistr_file         '${zfromfile}'"
 else if (/bg_zdistr_zfile/) print "bg_zdistr_zfile         '${zfile}'"
 else if (/ext_ps_file/) print "ext_ps_file           '${ext_ps_file}'"
 else if (/method/) print "method           '${nonlinfit}'"
 else if (/transferfunc/) print "transferfunc     '${transferfunc}'"
 else if (/outp_path/) print "outp_path		'${result_path}'"
 else if (/tomo_nbin/) print "tomo_nbin		'${nz}'"
 else if (/tomo_id/) print "tomo_id		'${run_ident}_source'"	
 else if (/tomo_bins/) print "tomo_bins               '${binlist}'"
 else if (/tomo_nlbin/) print "tomo_nlbin              '${nl}'"
 else if (/tomo_lmin/) print "tomo_lmin               '${lmin}'"
 else if (/tomo_lmax/) print "tomo_lmax               '${lmax}'"
 else if (/tomo_real/) print "tomo_real               '${cov_space}'"
 else if (/tomo_ntbin/) print "tomo_ntbin               '${nt}'"
 else if (/tomo_tmin/) print "tomo_tmin               '${tbmin}'"
 else if (/tomo_tmax/) print "tomo_tmax               '${tbmax}'"
 else if (/tomo_print/) print "tomo_print              '${printzpg}'"
 else if (/A_survey/) print "A_survey               '${area_source}'"
 else if (/A_ia/) print "A_ia                    '${aia}'"
 else if (/halo_massfunc_type/) print "halo_massfunc_type         '${hmf_type}'"
 else if (/halo_use_2h/) print "halo_use_2h               '${flag_2h}'"      
 else if (/halo_use_hod/) print "halo_use_hod               '${use_hod}'" 
 else if (/halo_hod_nbin/) print "halo_hod_nbin               '${nz_fg}'"
 else if (/halo_bias_file/) print "halo_bias_file               '${biasfile}'"
 else print $0
}' ${result_path}/thps.param > ${result_path}/thps_kids_${run_ident}_source.param
rm -f ${result_path}/thps.param

awk '{
  if (/tomo_id/) print "tomo_id		'${run_ident}_lens'"	
  else if (/A_survey/) print "A_survey               '${area_lens}'"
  else print $0
}' ${result_path}/thps_kids_${run_ident}_source.param > ${result_path}/thps_kids_${run_ident}_lens.param

awk '{
  if (/tomo_id/) print "tomo_id		'${run_ident}_cross'"	
  else if (/A_survey/) print "A_survey               '${area_source}'"
  else print $0
}' ${result_path}/thps_kids_${run_ident}_source.param > ${result_path}/thps_kids_${run_ident}_cross.param



### run covariance calculation
if [ $do_cov -eq 1 ]
then
  cd ${repo_path}/psvareos/proc/

  ./thps_cov ${result_path}/thps_kids_${run_ident}_lens.param 0 $cov_ng $cov_g 1 1 1 1 $covtype $noiseflag  # baseline ee+en+nn real-space covariance, G+NG terms
  cp ${result_path}/thps_cov_${run_ident}_lens_list.dat ${result_path}/thps_cov_${run_ident}_lens_list_insurvey.dat  # remaining files will be overwritten by SSC run

  ./thps_cov ${result_path}/thps_kids_${run_ident}_source.param 0 $cov_ng $cov_g 0 0 1 1 $covtype $noiseflag  # ee real-space covariance using source survey area, G+NG terms
  cp ${result_path}/thps_cov_${run_ident}_source_list.dat ${result_path}/thps_cov_${run_ident}_source_list_insurvey.dat  # remaining files will be overwritten by SSC run

  if [ $cov_ssc -eq 1 ]
  then
    ./thps_cov ${result_path}/thps_kids_${run_ident}_lens.param 1 0 0 1 1 1 1 $covtype $noiseflag  # baseline ee+en+nn real-space covariance, SSC term

    ./thps_cov ${result_path}/thps_kids_${run_ident}_source.param 1 0 0 0 0 1 1 $covtype $noiseflag  # ee real-space covariance using source survey area, SSC term

    ./thps_cov ${result_path}/thps_kids_${run_ident}_cross.param 1 0 0 1 1 1 1 $covtype $noiseflag  # to extract cross-variance (SSC only)
  fi

  cd $home
else
  echo "Skip calculation of covariance."
fi



### post-processing
if [ $do_assembly -eq 1 ]
then
  if [[ $cov_ssc -eq 1 && $cov_ng -eq 1 && $cov_g -eq 1 ]]  #full version
  then

    # merge with SSC term
    awk '{ print $NF }' ${result_path}/thps_cov_${run_ident}_lens_list.dat > ${result_path}/tmp.dat
    paste ${result_path}/thps_cov_${run_ident}_lens_list_insurvey.dat ${result_path}/tmp.dat > ${result_path}/thps_cov_${run_ident}_lens_list_combined.dat
    awk '{ print $NF }' ${result_path}/thps_cov_${run_ident}_source_list.dat > ${result_path}/tmp.dat
    paste ${result_path}/thps_cov_${run_ident}_source_list_insurvey.dat ${result_path}/tmp.dat > ${result_path}/thps_cov_${run_ident}_source_list_combined.dat
    rm -f ${result_path}/tmp.dat


    # replace ee auto-covariance elements in baseline
    awk '{ if (($3==0)&&($4==0)&&($9==0)&&($10==0)) { do { getline < "'${result_path}'/thps_cov_'${run_ident}'_source_list_combined.dat" } while ($1=="") } print $0}' ${result_path}/thps_cov_${run_ident}_lens_list_combined.dat > ${result_path}/thps_cov_${run_ident}_list.dat
    

    # replace & rescale cross-variance terms
    # en-ee
    awk '{ if (($3==2)&&($4==0)&&($9==0)&&($10==0)) { printf "%i %i\t%i %i\t%i %i\t\t%i %i\t%i %i\t%i %i\t\t%15.10e\t%15.10e\t", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13*'${area_lens}'/'${area_source}',$14*'${area_lens}'/'${area_source}'; do { getline < "'${result_path}'/thps_cov_'${run_ident}'_cross_list.dat" } while (!(($3==2)&&($4==0)&&($9==0)&&($10==0))); printf "%15.10e\n", $13*'${area_source}'/'${area_lens}' } else print $0 }' ${result_path}/thps_cov_${run_ident}_list.dat > ${result_path}/tmp.dat # in-survey terms rescaled to be divided by larger survey area
    mv ${result_path}/tmp.dat ${result_path}/thps_cov_${run_ident}_list.dat

    # nn-ee
    awk '{ if (($3==2)&&($4==2)&&($9==0)&&($10==0)) { printf "%i %i\t%i %i\t%i %i\t\t%i %i\t%i %i\t%i %i\t\t%15.10e\t%15.10e\t", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13*'${area_lens}'/'${area_source}',$14*'${area_lens}'/'${area_source}'; do { getline < "'${result_path}'/thps_cov_'${run_ident}'_cross_list.dat" } while (!(($3==2)&&($4==2)&&($9==0)&&($10==0))); printf "%15.10e\n", $13*'${area_source}'/'${area_lens}' } else print $0 }' ${result_path}/thps_cov_${run_ident}_list.dat > ${result_path}/tmp.dat # in-survey terms rescaled to be divided by larger survey area
    mv ${result_path}/tmp.dat ${result_path}/thps_cov_${run_ident}_list.dat


  elif [[ $cov_ssc -eq 0 && $cov_ng -eq 0 && $cov_g -eq 1 ]]  #Gaussian/noise only
  then

    # replace ee auto-covariance elements in baseline
    awk '{ if (($3==0)&&($4==0)&&($9==0)&&($10==0)) { do { getline < "'${result_path}'/thps_cov_'${run_ident}'_source_list.dat" } while ($1=="") } print $0}' ${result_path}/thps_cov_${run_ident}_lens_list.dat > ${result_path}/thps_cov_${run_ident}_list.dat  

    # replace & rescale cross-variance terms
    # en-ee
    awk '{ if (($3==2)&&($4==0)&&($9==0)&&($10==0)) { printf "%i %i\t%i %i\t%i %i\t\t%i %i\t%i %i\t%i %i\t\t%15.10e\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13*'${area_lens}'/'${area_source}' } else print $0 }' ${result_path}/thps_cov_${run_ident}_list.dat > ${result_path}/tmp.dat # in-survey terms rescaled to be divided by larger survey area
    mv ${result_path}/tmp.dat ${result_path}/thps_cov_${run_ident}_list.dat

    # nn-ee
    awk '{ if (($3==2)&&($4==2)&&($9==0)&&($10==0)) { printf "%i %i\t%i %i\t%i %i\t\t%i %i\t%i %i\t%i %i\t\t%15.10e\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13*'${area_lens}'/'${area_source}' } else print $0 }' ${result_path}/thps_cov_${run_ident}_list.dat > ${result_path}/tmp.dat # in-survey terms rescaled to be divided by larger survey area
    mv ${result_path}/tmp.dat ${result_path}/thps_cov_${run_ident}_list.dat

  else
    echo "No covariance rescaling as not all required terms requested."
  fi

  awk '{ if (($1!="")&&($1==$7)&&($2==$8)&&($3==$9)&&($4==$10)&&($5==$11)&&($6==$12)) print $0 }' ${result_path}/thps_cov_${run_ident}_list.dat > ${result_path}/thps_cov_${run_ident}_list_diag.dat   # get diagonal entries only

else
  echo "Skip assembly of covariance."
fi


if [ $do_bp -eq 1 ]
then
  cd ${repo_path}/bandpowers/

  ./xi2bandpowcov ${result_path} ${run_ident} ${nt} ${tbmin} ${tbmax} ${tcutmin} ${tcutmax} ${nbp} ${bpmin} ${bpmax} ${apod_width} 1 0

  ./xi2bandpowcov ${result_path} ${run_ident} ${nt} ${tbmin} ${tbmax} ${tcutmin} ${tcutmax} ${nbp} ${bpmin} ${bpmax} ${apod_width} -1 0  # B-mode version

  ./xi2bandpowcov ${result_path} ${run_ident} ${nt} ${tbmin} ${tbmax} ${tcutmin} ${tcutmax} ${nbp} ${bpmin} ${bpmax} -1. 1 0   # unapodised version, E-mode

  cd $home
elif [ $do_bp -eq 2 ]  # preserving individual covariance terms
then
  cd ${repo_path}/bandpowers/

  ./xi2bandpowcov ${result_path} ${run_ident} ${nt} ${tbmin} ${tbmax} ${tcutmin} ${tcutmax} ${nbp} ${bpmin} ${bpmax} ${apod_width} 1 1  # std apodised E-mode, term 1

  ./xi2bandpowcov ${result_path} ${run_ident} ${nt} ${tbmin} ${tbmax} ${tcutmin} ${tcutmax} ${nbp} ${bpmin} ${bpmax} ${apod_width} 1 2  # std apodised E-mode, term 2

  ./xi2bandpowcov ${result_path} ${run_ident} ${nt} ${tbmin} ${tbmax} ${tcutmin} ${tcutmax} ${nbp} ${bpmin} ${bpmax} ${apod_width} 1 3  # std apodised E-mode, term 3

  cd ${result_path}/
  paste thps_cov_${run_ident}_bandpower_E_apod_1_list.dat thps_cov_${run_ident}_bandpower_E_apod_2_list.dat thps_cov_${run_ident}_bandpower_E_apod_3_list.dat > tmp.dat
  awk '{ if ($1=="") printf "\n"; else { printf "%i %i\t%i %i\t%i\t\t%i %i\t%i %i\t%i\t\t%15.10e\t%15.10e\t%15.10e\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$22,$33  } }' tmp.dat > thps_cov_${run_ident}_bandpower_E_apod_covterms_list.dat
  rm -f tmp.dat

  cd $home
else
  echo "Skip calculation of bandpower covariance."
fi


cd $home
cat $0 > ${result_path}/thps_cov_${run_ident}.log
echo "  All done."
