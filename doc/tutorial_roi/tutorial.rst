==================
NeuroPipe Tutorial
==================



:author: Alexa Tompary
:email: ntblab@princeton.edu



.. contents::



-----------------------------------------------
Chapter 5 - ROI analysis of an adaptation study
-----------------------------------------------

If you've completed the FIR tutorial, or if you've collected and analyzed data using a FIR model, and would like to investigate brain activity in specific, pre-determined areas of the brain, you're in the right place. These regions can be chosen anatomically, by running a high resolution structural scan on a subject and outlining the area of the brain you're investigating, or functionally, by using a localizer sequence designed to activate the brain areas you're interested in. 

For example, in this study, subjects completed a task that required attention to alternating blocks of either faces or houses. By using a GLM model to compare brain activity in response to faces or houses, we can identify areas of the brain that are face- or scene-selective. Then, we can look at a time series of those brain areas as the subjects complete a different task. 

In this tutorial, we will take the data that was analyzed in the previous tutorial on FIR models, and then prepare a dataset of time series information about different regions of interest (ROIs) in the brain. That dataset can then be plotted to see differences in responses for different stimuli, adaptation effects, etc.

Picking ROIs
============

.. admonition:: you are here

   ~/ppa-hunt/subjects/0223101_conatt01

First, you have to pick the coordinates of the ROIs you are interested in analyzing. These areas have already been chosen for you; since this study was interested in adaptation in scene-selective areas of the brain, we will be looking at the right and left parahippocampal place area (PPA), retrosplenial cortex (RSC), and transverse occipital sulcus (TOS). 

Then the coordinates of these areas need to be chosen. Normally, you will run some sort of localizing sequence to activate a certain part of the brain, and then pick the peak voxels in those areas.  Those coordinates have already been picked for you::

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/dev/doc/tutorial_roi/roi.txt > design/roi.txt
 
This file needs to be formatted in 3 columns, with one line for each ROI and 1 column per coordinate direction (in x y z order).  Take a look::

 $ less design/roi.txt
 
Finally, we need some information about the location of these coordinates within the brain volume that we picked them found. This way, we can tranform the location of the coordinates from the space of the localizer run to the space of the runs that our time courses will be extracted from. Normally this information will be created and stored in the Feat directory of your localizer run, in a file called *example_func.nii.gz*. For the purposes of this tutorial, we will simulate the localizer run's Feat directory and then provide the file for you::

 $ mkdir -p analysis/firstlevel/localizer_hrf.feat/reg
 $ cp /exanet/ntb/packages/neuropipe/example_data/0223101_conatt01_example_func.nii.gz analysis/firstlevel/localizer_hrf.feat/reg/example_func.nii.gz
 
 Note: to copy the file, you must qrsh onto a node if you're working from Rondo. If you are working outside of Princeton University, or can't access the file, email ntblab@princeton.edu for help.
 
**Summary**::

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/dev/doc/tutorial_roi/roi.txt > design/roi.txt
 $ less design/roi.txt
 $ mkdir p- analysis/firstlevel/localizer_hrf.feat/reg
 $ cp /exanet/ntb/packages/neuropipe/example_data/0223101_conatt01_example_func.nii.gz analysis/firstlevel/localizer_hrf.feat/reg/example_func.nii.gz

Preparing for ROI analysis
==========================
 
Finally, we are ready to look through *roi.sh*, located in the *scripts* folder. Before we run the commands, let's make sure that we have everything ready to go::

 $ less scripts/roi.sh
 
The information in the header says to make sure that the variables needed to run this script need to be set in globals.sh. These include the location of the text file we just made. Let's check *globals.sh* to see where this file should be located::

 $ less globals.sh

The path and file name of *roi.txt* match what is listed in *globals.sh*, so our ROI script will be able to find that file when it needs them. While we're in there, make sure that the other parameters in *roi.sh* are correctly filled in. The kernel size and type are also what we'll be using for this analysis. For your own projects, once you decide on your kernel information, *globals.sh* is the place to set it.

**Summary**::

 $ less scripts/roi.sh
 $ less globals.sh


The mysterious inner workings of *roi.sh*
=========================================

Let's open *roi.sh* up again and see what it does. (It's always a good idea to know what you are doing to your data!)::

 $ less scripts/roi.sh

First, the script reads in the ROI information we supply with our two text files. Then, it calls *transform-coords-dest.sh*, which transforms the coordinates of the peak voxels of each ROI into the space of the run(s) that you're interested in running this analysis on. This way, the coordinates that you collected earlier, on a localizer run, will line up with the same regions in the runs you're extracting information from.
Those runs are specified by adding one or more feat directories as options to the command.

Now that your ROI coordinates are correctly aligned to your run of interest, the script pulls out the 'cope' files from the run, which contain time series information based on the contrasts that you set up when modeling the run in a GLM. Then, it calls *transform-to-psc.sh* to convert the signal intensity in each cope file to percent signal change. 

Finally, *roi.sh* calls *extract-stat-at-coords.sh*, which extracts the time course of your ROI coordinates for each time point of each cope, and organizes them as one csv file per analyzed run.

So, let's do it! If you've completed the FIR tutorial, you can try this out on the two 'encoding_fir' runs that you've analyzed already.

 $ scripts/roi.sh analysis/firstlevel/encoding_fir01.feat analysis/firstlevel/encoding_fir02.feat
 
You should now have cvs files in *results/roi* that can be imported into R, Excel, or another program of your choice, either for running statistics or plotting your data. From here on out, your analysis will depend on the aims of your study. Good luck!





 
