#!/bin/bash

RES="ASH83"

################################################################3
echo " Generating stripped topology and computing RMSD ..."

rm rmsd.in 2> /dev/null
cat >> rmsd.in <<- EOF
parm   ../prep/2C9V_CuCuSite${RES}.prmtop
trajin prod_1.mdcrd
trajin prod_2.mdcrd
trajin prod_3.mdcrd
trajin prod_4.mdcrd

unwrap ^1,2
center @CU mass origin
image origin center
strip :WAT,Na+,Cl- outprefix strip
trajout view.dcd CHARMM
run

clear all

parm   strip.2C9V_CuCuSite${RES}.prmtop
trajin view.dcd

rms BackBondRMSD @N,CA,C,O&!:WAT first out ${RES}BackBoneRMSD.dat mass
run
EOF

cpptraj -i rmsd.in > rmsd.log
mv "strip.2C9V_CuCuSite${RES}.prmtop" "view.prmtop"
frmtot=$(cpptraj -p view.prmtop -y view.dcd -tl | awk '{print $2}')
strfrm=$(($frmtot - 5000))
echo " Last 100 ns is from frame ${strfrm} to ${frmtot}."
################################################################3

################################################################3

mkdir PBSA-${RES} 2> /dev/null
cp view.prmtop PBSA-${RES}/.

rm GetFrame.log 2> /dev/null
for frm in $(seq ${strfrm} 50 ${frmtot});do
  mkdir PBSA-${RES}/frm${frm} 2> /dev/null

  echo " Extracting frame ${frm} ..."

rm GetFrame${frm}.in 2> /dev/null
cat >> GetFrame${frm}.in <<- EOF
 parm    view.prmtop
 trajin  view.dcd ${frm} ${frm} 1
 trajout ${RES}_frm${frm}.rst7
 run

 quit
EOF
  cpptraj -i GetFrame${frm}.in >> GetFrame${frm}.log
  mv GetFrame${frm}.in GetFrame${frm}.log ${RES}_frm${frm}.rst7 PBSA-${RES}/frm${frm}/.
done

cd PBSA-${RES}
rm pbsa.key 2> /dev/null
cat >> pbsa.key <<- EOF
 Single point PB calculation
 &cntrl
  IPB=2,             ! Dielectric interface model with the level-set funciton
  INP=2,             ! Non-polar solvation free energy method   
  ntx=1,             ! Read formatted coordinates from inpcrd 
  imin=1,            ! Single-point energy evalulation 
 /

 &pb
  pbtemp=300,        ! Temperature for salt effects in PB equation 
  ivalence=0,        ! 
  istrng=100.0,      ! Ionic strength in mM for PB equation 
  epsin=4.000,       ! Solute region dielectric constant 
  epsout=78.2,       ! Solvent region dielectric constant 
  epsmem=78.2,       ! Membrane dielectric constant
  membraneopt=0,     ! Turn off/on implicit slab membrane
  mthick=40.0        ! Membrane thickness in Å
  mctrdz=0,          ! Membrane center in Z direction Å; 0 = centered at center of protein 
  poretype=0,        ! Turn off(0)/on(1) pore-searching algorithm
  radiopt=0,         ! Atomic radii from topology used; optimized radius (choice 1) for FE is missing 
  dprob=1.4,         ! Solvent probe radius for molecular surface definition  
  iprob=2.0,         ! Mobile ion probe radius used to define the Stern layer. 
  mprob=2.7,         ! Membrane lipid probe radius 
  sasopt=0,          ! Use solvent-excluded surface type for solute 
  triopt=1,          ! Use trimer arc dots to map analytical solvent excluded surface  
  arcres=0.25,       ! Resolution of dots (in Å) used to represent solvent-accessible arcs 
  maxarcdot=15000    ! 
  smoothopt=1,       ! Use weighted harmonic average of epsin and epsout for boundary grid edges across solute/solvent dielectric boundary 
  saopt=1,           ! Compute solute surface area 
  decompopt=2,       ! sigma decomposiiton scheme for non-polar solvation 
  use_rmin=1,        ! Use rmin for van der waals radi, improves agreement with TIP3P
  sprob=0.557,       ! Compute dispersion term using solvent probe radius (in Å) for solvent accessible surface area 
  vprob=1.300,       ! Compute non-polar cavity solvation free energy using olvent probe radius (in Å) for molecular volume 
  rhow_effect=1.129, ! Effective water density for non-polar dispersion term
  use_sav=1,         ! Use molecular volume for cavity term
  maxsph=400,        ! Approximate number of dots to represent the maximum atomic solvent accessible surface
  npbopt=0,          ! Linear PB equation is solved  
  solvopt=1,         ! ICCG/PICCG iterative solver 
  accept=0.001,      ! Iteration convergence criterion   
  maxitn=100,        ! Maximum number of iterations for finite difference solver 
  fillratio=1.5,     ! ratio between longest dimension of rectangular finite-difference grid and that of the solute    
  space=0.5,         ! Grid spacing for finite-difference solver 
  nfocus=2,          ! Number of successive FD calculations for electrostatic focusing  
  fscale=8,          ! Ratio between coarse and fine grid spacings in electrostatic focussing 
  npbgrid=1,         ! Frequency for regenerating finite-difference grid 
  bcopt=5,           ! Boundary grid potentials computed using all grid charges
  eneopt=2,          ! Reaction field energy computed using dielectric boundary surface charges 
  frcopt=2,          ! reaction field forces and dielectric boundary forces computed with dielectric boundary surface polarized charges 
  scalec=0,          ! Dielectric boundary surface charges are not scaled before computing reaction field energy and forces
  cutfd=5,           ! Atom-based cutoff distance to remove short-range finite-difference interactions and to add pairwise charge-based interactions
  cutnb=0,           ! Atom-based cutoff distance for van der Waals interactions and pairwise Coulombic interactions when eneopt=2   
  !phiout=1,         ! Output spatial distribution of electrostatic potential f
  !phiform=2,        ! DX format of the electrostatic potential file for VMD
  !outlvlset=true,   ! Output total level set, used in locating interfaces between regions of differing dielectric constant
  !outmlvlset=true,  ! Output membrane level set, used in locating interfaces between regions of differing dielectric constant
  !npbverb=1,        ! Output verbosity; 1 is verbose 
  !isurfchg=1,       ! Save surface changes to a file
 /
EOF

rm run.sh 2> /dev/null
cat >> run.sh <<- EOF
#!/bin/bash

for frm in \$(seq ${strfrm} 50 ${frmtot});do
  echo -e "\n  Analyzing frame \${frm}   ... \r"
  cd frm\${frm}
  pbsa -O -i ../pbsa.key -o pbsa.out -p ../view.prmtop -c ${RES}_frm\${frm}.rst7 &
  cd ../
done

echo " All Submitted "

EOF

chmod u+x "run.sh"

rm "read.sh" 2> /dev/null
cat >> "read.sh" <<- EOF
for frm in \$(seq ${strfrm} 50 ${frmtot});do
  E=\$(grep "Etot   =" frm\${frm}/pbsa.out  | tail -n1  | awk '{print \$3}')
  printf "%10s %10.4f \n" \$frm \$E
done > Eng.dat
EOF

chmod u+x "read.sh"

cd ../

