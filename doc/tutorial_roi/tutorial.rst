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

First, you have to pick the coordinates of the ROIs you are interested in analyzing. These areas have already been chosen for you; since this study was interested in adaptation in scene-selective areas of the brain, we will be looking at the right and left parahippocampal place area (PPA), retrosplenial cortex (RSC), and transverse occipital sulcus (TOS). These brain regions need to be organized in a text file with one region per line. The list has already been made for you::

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/dev/doc/tutorial_roi/roi_regions.txt > design/roi_regions.txt
 
Open this file and note that each area is designated in one word, with one ROI per line. The first letter of each ROI is 'r' or 'l', depending on whether the ROI is in the right or left hemisphere. This format is important if you wish to use neuropipe scripts to run your ROI analysis::

 $ less design/roi_regions.txt

Then the coordinates of these areas need to be chosen. Normally, you will run some sort of localizing sequence to activate a certain part of the brain, and then pick the peak voxels in those areas.  Those coordinates have already been chosen for you::

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/dev/doc/tutorial_roi/roi.txt > design/roi.txt
 
This file needs to be formatted in 3 columns, with one line for each ROI and 1 column per coordinate direction (in x y z order).  Take a look::

 $ less design/roi.txt
 
**Summary**::

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/dev/doc/tutorial_roi/roi_regions.txt > design/roi_regions.txt
 $ less design/roi_regions.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/dev/doc/tutorial_roi/roi.txt > design/roi.txt
 $ less design/roi.txt

Preparing for ROI analysis
==========================
 
Finally, we are ready to look through *roi.sh*, located in the *scripts* folder. Before we run the commands, let's make sure that we have everything ready to go::

 $ less scripts/roi.sh
 
The information in the header says to make sure that the variables needed to run this script need to be set in globals.sh. These include the locations of the two text files we just made. Let's check *globals.sh* to see where these files should be located::

 $ nano globals.sh

The paths and file names of *roi_regions.txt* and *roi.txt* match what is listed in *globals.sh*, so our ROI script will be able to find those files when it needs them. While we're in there, make sure that the other parameters in *roi.sh* are correctly filled in. Since the data we're using (from our FIR model) had an 18 second window, FIR_LAG should start at lag 0 and end at lag 17, just like it does in *globals.sh*. The kernel size and type are also what we'll be using for this analysis. For your own projects, once you decide on the length of your window, and your kernel information, *globals.sh* is the place to set it.

**Summary**::
 $ less scripts/roi.sh
 $ nano globals.sh


The mysterious inner workings of *roi.sh*
=========================================

Let's open *roi.sh* up again and see what it does. (It's always a good idea to know what you are doing to your data!)::

 $ less scripts/roi.sh

First, the script reads in the ROI information we supply with our two text files. Then, it calls *transform-coords-dest.sh*, which transforms the coordinates of the peak voxels of each ROI into the space of the run(s) that you're interested in running this analysis on. Those are specified by adding feat directories as options to the command.

Now that your ROI coordinates are situating in the space of the run, the script pulls out the 'cope' files from the run, which contain time series information based on the contrasts that you set up when modeling the run in a GLM. Then, it calls *transform-to-psc.sh* to convert the signal intensity in each cope file to percent signal change. 

Then, *roi.sh* calls *extract-stat-at-coords.sh*, which extracts the time course of your ROI coordinates for each time point of each cope, and organizes them as a csv file. And finally, the data is loaded into R to be organized for future use as well.

So, let's do it!

 $ scripts/roi.sh analysis/firstlevel/encoding_fir01.feat analysis/firstlevel/encoding_fir02.feat
 
You should now have cvs files in *results/roi* along with an .Rdat file that can be loaded into R for running statistics or plotting your data. For example, you can plot the time course for each ROI for visual comparison between experiment conditions, and also differences in the activity of each brain region.

.. image:: https://github.com/ntblab/neuropipe-support/raw/dev/doc/tutorial_roi/ggplot2-graph.png

And, after running this ROI analysis on the data from two runs each from 18 subjects, we can start to see a difference in the BOLD response caused by adaptation -- that is, when a novel image was presented after a series of two objects that had been previously shown (RC_NFI), no adaptation occurs because the sequence of images is not learned. Likewise, when a series of two novel images are presented before an image that has already been shown (NC_RFI), since the sequence of images as never been learned before, no adaptation appears. However, when a series of three images appear in an order that has been previously shown (RC_RFI), the appearance of the third image is expected, and adaptation is present. We can see this in the decreased BOLD peak in the time course for that category.

.. image:: https://github.com/ntblab/neuropipe-support/raw/dev/doc/tutorial_roi/ggplot2-graph-all.png





 
