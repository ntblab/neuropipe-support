==================
NeuroPipe Tutorial
==================



:author: Mason Simon
:Email: mgsimon@princeton.edu



.. contents::



------------------------------------
Chapter 1 - Within-Subjects Analysis
------------------------------------


Introduction
============

NeuroPipe is a framework for reproducible fMRI research projects. It's optimized for projects composed of within-subjects analyses that are mainly identical, which are combined into an across-subject analysis. If this describes the structure of your project, using NeuroPipe will make it simple for you to run complex analyses that can be reproduced entirely by running a single command. This simplifies the task of ensuring your analysis is bug-free, by letting you easily make a fix and test it. And, it allows others to re-run your analysis to verify your work is correct, or to build upon your project once you've finished it.

This tutorial will walk you through using NeuroPipe for a within-subjects analysis on one subject, that we will then repeat for a second subject to demonstrate how NeuroPipe facilitates these sorts of analyses with minimal redundant code and effort. For our example analysis, we fit a GLM to data collected while subjects viewed blocks of scene images and face images, in order to locate the PPA region in these subjects.


Conventions used in this tutorial
---------------------------------

- Commands that must be executed on the command line will look like this::

  $ *command-to-run*

- Files will be written like this: *path/to/filename.ext*.
- Text that must be copied exactly as specified will be written inside of double quotes, like this: "text to copy".



Installing NeuroPipe
--------------------

Requirements:

- unix-based computer (use rondo if you're at princeton)
- BXH XCEDE tools
- FSL


First, download neuropipe with the command::

  $ wget http://github.com/mason-work/neuropipe/tarball/master

Now extract that file, and rename the extracted directory "neuropipe"::

  $ tar -xzvf *neuropipe*.tar.gz
  $ rm *neuropipe*.tar.gz
  $ mv *neuropipe* neuropipe



Setting up your NeuroPipe project
=================================

To set up our new project in NeuroPipe, run this command::

  $ neuropipe/np ppa-hunt

That command sets up a rich folder structure at ppa-hunt for you to build your project in. Move into that directory and take a look around::

  $ cd ppa-hunt
  $ ls

You should see a *README.txt* file, a command called *scaffold*, a file called *protocol.txt*, a directory called *subject-template*, and maybe a few other directories. Let's start by opening *README.txt*::

  $ less README.txt

The first instruction it has for us in the Getting Started section is to open up *protocol.txt* and follow its instructions. Hit "q" to quit out of *README.txt*, then open *protocol.txt*::

  $ less protocol.txt

It says we need to fill it in with details on the data collection protocol. We'll just download a *protocol.txt* file that describes the ppa-hunt data you're about to analyze. Hit "q" to quit out of *protocol.txt*, then run these commands::

  $ rm protocol.txt
  $ wget http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/protocol.txt

Take a look at the newly downloaded *protocol.txt*::

  $ less protocol.txt

Hit "q", and open *README.txt* again::

  $ less README.txt

The next instruction it gives us is to open *subject-template/copy/run-order.txt*. Hit "q", then open that file::

  $ less subject-template/copy/run-order.txt

As with *protocol.txt*, a *run-order.txt* file has already been prepared for you. Download that file, and put it where *README.txt* says to put it::

  $ curl http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/run-order.txt > subject-template/copy/run-order.txt

Open *README.txt* one last time::

  $ less README.txt

It says the next step is to collect data for a subject. Lucky you, that's already been done, so skip that step. The final instruction is to run the command *./scaffold SUBJECT_ID*, with a real subject ID inserted in place of "SUBJECT_ID".


Setting up a subject to analyze
===============================

Our subject ID is "0608101_conatt02", so run this command::

  $ ./scaffold 0608101_conatt02

*scaffold* tells you that it set up a subject directory at *subjects/0608101_conatt02* and that you should read the README.txt file there if this is your first time setting up a subject. Move into the subject's directory, and do what it says::

  $ cd subjects/0608101_conatt02
  $ less README.txt

This *README.txt* says your first step is to get some DICOM data and put it in a Gzipped TAR archive at *data/raw.tar.gz*. Like I mentioned, the data has already been collected. It's even TAR-ed and Gzipped. Hit "q" to get out of *README.txt* and get the data with this command::

  $ curl http://www.princeton.edu/ntblab/resources/0608101_conatt02.tar.gz > data/raw.tar.gz


Preparing your data for analysis
================================

Open *README.txt* again::

  $ less README.txt

We already set up *run-order.txt*, and put it in *subject-template/copy/*. That directory is special. Any file or folder in it will be copied into each new subject directory that's created by *scaffold*. To check that *run-order.txt* came through all right, hit "q" to get out of *README.txt*, and run this command::

  $ less run-order.txt

You should see that it's identical to the one we downloaded before. Hit "q", then open *README.txt* one last time::

  $ less README.txt

It says that we should proceed by doing various transformations on the data, and then running a quality assurance tool to make sure the data is usable. The transformations make the data more palatable to FSL_, which we will use for analysis. As *README.txt* says, you do all that with this command::

  $ ./analyze.sh

.. _FSL: http://www.fmrib.ox.ac.uk/fsl/

Later, we'll flesh out *analyze.sh* to do more than just prepare your data for analysis. Once *analyze.sh* finishes, take a look in data/nifti. There should be a pair of .bxh/.nii.gz files for each pulse sequence listed in run-order.txt (excluding the ones called ERROR_RUN). Open the .nii.gz files with FSLView_, if you'd like, using a command like this::

  $ fslview data/nifti/0608101_conatt02_t1_mprage_sag01.nii.gz

.. _FSLView: http://www.fmrib.ox.ac.uk/fsl/fslview/index.html

There's also a new folder at data/qa. Peek in and you'll see a ton of files. These are organized and presented by an HTML file at *data/qa/index.html*. Open it with this command::

  $ firefox data/qa/index.html

Use the "(What's this?)" links to figure out what all the diagnostics mean. When then diagnostics have convinced you that there are no quality issues with this data (such as lots of motion) that would make it uninterpretable, close firefox.



GLM analysis with FEAT
======================

Now that you've got some data, and know its quality is sufficient for analysis, it's time to do an analysis. We'll use FSL's FEAT to perform a GLM-based analysis. take a look at `FEAT's manual`_ to learn more about FEAT and GLM analysis in general.

.. _FEAT's manual: http://www.fmrib.ox.ac.uk/fsl/feat5/index.html

To set the parameters of the analysis, you'll need to know the experimental design. Open *protocol.txt* in the project directory and read it.

Now launch FEAT::

  $ feat

It opens to the Data tab. 


The Data tab
------------

Click "Select 4D data" and select the data file *data/nifti/localizer01.nii.gz*. Set "Output directory" to *analysis/firstlevel/localizer_hrf*. FEAT should have detected "Total volumes" as 244, but it may have mis-detected "TR (s)" as 3.0; if so, change that to 1.5. Because *protocol.txt* indicated there were 6s of disdaqs, and TR length is 1.5s, set "Delete volumes" to 4. Set "High pass filter cutoff (s)" to 128.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-data.png

Go to the Pre-stats tab.


The Pre-stats tab
-----------------

Change "Slice timing correction" to "Interleaved (0,2,4 ...". Leave the rest of the settings at their defaults.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-pre-stats.png

Go to the Stats tab.


The Stats tab
-------------

Check "Add motion parameters to model". Now we must use the description of the experimental design from *protocol.txt* to set up regressors for our GLM. *protocol.txt* tells us that blocks consisted of 12 trials, each 1.5s long, with 12s rest between blocks, and 6s rest at the start to let the scanner settle down. That 6s at the start was taken care of in the Data tab, so we have a design that looks like Scene, rest, Face, rest, Scene, rest, ...

Click the "Model setup wizard" button. It has an option for "rArBrArB...", which isn't quite what we want, but close. Click that button, and set the rest period to 12s, A period to 18s (12 trials * 1.5s each), and B period to 18s. Click "Process" and close the graph that shows up. Now click "Full model setup", so we can eliminate that extra 12s rest at the start that the Model setup wizard gave us.

First, set EV name to "scene". FSL calls regressors EV's, short for Explanatory Variables. The wizard set the regressor shape to Square, which is right. Skip is 0. Off period is 42s, because after the wave is on, there are 12s of rest, then 18s for the other wave to go on (other block type), then another 12s of rest. "On period" is 18s, like we set it to be. Hover over the "Phase" text, and FEAT will explain that the wave starts with a full off period (42s in our case), and "Phase" can be used to adjust this; FEAT set it to 30s so that there was a 12s rest period before this wave comes on, but we don't want that, so set Phase to 42 to eliminate the off period at the start. Leave "Stop after" at -1, so the wave continues as long as necessary. because we don't believe the fMRI signal will actually look like a square wave, we convolve it with a function that's intended to model the hemodynamic response; change Convolution to Double-Gamma HRF. Now we must set up the face regressor. Click tab 2.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-stats-ev1.png

Change EV name to "face". Look at the Phase setting. FEAT set it to 0, which means that there will be a full 42s of rest before this wave gets going. But, because we have no rest at the start, there will only be 18s for the scene wave + 12s rest = 30s before we want the face wave to start. So adjust Phase to be 12. Change Convolution to Double-Gamma HRF, like we did for the scene regressor.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-stats-ev2.png

Now go to the Contrasts & F-tests tab. We don't care to run any F-tests, so decrease "F-tests" from 1 to 0. FEAT already has the contrasts set up that we'd want, they're just named differently than we want. In each of the Title fields, replace "A" with "scene" and "B" with "face".

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-stats-contrasts-and-f-tests.png

Close that window, and FEAT should show you a graph of your model. If it doesn't look like the one below, make sure you followed the instructions correctly.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-model-graph.png

Go to the Registration tab.


The Registration tab
--------------------

It should already have a "Standard space" image selected; leave it with the default, but change the drop-down menu from Normal search to No search. Check "Initial structural image", and select the file *subjects/0608101_conatt02/data/nifti/0608101_conatt02_t1_flash01.nii.gz*. Check "Main structural image", and select the file *subjects/0608101_conatt02/data/nifti/0608101_conatt02_t1_mprage_sag01.nii.gz*.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-registration.png

That's it! Hit Go. A webpage should open in your browser showing FEAT's progress. Once it's done, this webpage provides a useful summary of the analysis you just ran with FEAT. Later, we'll make a webpage for this subject to gather information like this FEAT report, the QA results, and plots summarizing this subject's data. But for now, let's continue with the hunt for the PPA.


Finding the PPA
===============

Launch FSLView::

  $ fslview

Click File>Open... and select *analysis/firstlevel/localizer_hrf.feat/mean_func.nii.gz*. Click File>Add... *analysis/firstlevel/localizer_hrf.feat/stats/zstat3.nii.gz*. *zstat3.nii.gz* is an image of z-statistics for the scene>face contrast being different from 0, so high intensity values in a voxel indicate that the scene regressor caught much more of the variance in fMRI signal at that voxel than the face regressor. To find the PPA, we'll look for regions with really high values in *zstat3.nii.gz*. Set the Min threshold at the top of FSLView to something like 8, then click around in the brain to see what regions had contrast z-stats at that threshold or above. See if you can find a pair of bilateral regions with zstat's at a high threshold, around the middle of the brain; that'll be the PPA.


Repeating the analysis for a new subject
========================================

Now lets see how to perform this analysis on a new subject. Copy the file *analysis/firstlevel/localizer_hrf.feat/design.fsf* to *fsfs/localizer_hrf.fsf*. This fsf file contains all the information needed to re-run exactly the analysis we just did. Typing *feat localizer_hrf.fsf* would do that. But we want to run that analysis on different data, and we want to put the output in a different place. So that we don't have to redo this step for each new subject, our approach will be to turn this fsf file into a template that we fill-in (automatically) for each new subject.

1. Open localizer_hrf.fsf in your text editor.
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>", if you're familiar with PHP, this syntax will be familiar
  #. on the line starting with "set fmri(regstandard) ", replace all of the text inside the quotes with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set feat_files(1)", replace all of the text inside the quotes with "<?= $DATA_FILE_PREFIX ?>"
  #. on the line starting with "set initial_highres_files(1) ", replace all of the text inside the quotes with "<?= $INITIAL_HIGHRES_FILE ?>"
  #. on the line starting with "set highres_files(1)", replace all of the text inside the quotes with "<?= $HIGHRES_FILE ?>"

2. save that file as localizer_hrf.fsf.template

Now we have a template. To use it, we'll need a script that fills it in appropriately for each subject. This filling-in process is called rendering, and a script that does most of the work for you has already been provided at *scripts/render-fsf-templates.sh*. Open that in your text editor.

It has a function called render_firstlevel. we'll use that to render the localizer template we just made. Add these lines to the end of the file::

  render_firstlevel $FSF_DIR/localizer_hrf.fsf.template \
                    $FIRSTLEVEL_DIR/localizer_hrf.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_localizer01 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage_sag01.nii.gz \
                    > $FSF_DIR/localizer_hrf.fsf           
                  
*prep.sh* already calls this *render-fsf-templates.sh* script, so the only thing left to do is to automatically run *feat* on the rendered fsf file. Make a new script called *hrf.sh*, and fill it with these lines::

  #!/bin/bash
  source globals.sh
  feat $FSF_DIR/localizer_hrf.fsf

Open *analyze.sh* in your text editor. After the line that runs *prep.sh*, add this line::
  
  bash hrf.sh

That should do it! Let's test this on a new subject.

#. cd back to your project folder.
#. run ./scaffold 0608102_conatt02.
#. cd into that new subject's directory.
#. `download data for this subject`_, and put it at *data/raw.tar.gz*.
#. run ./analyze.sh, and watch everything go.

.. _download data for this subject: https://docs.google.com/leaf?id=0B5IAU_xL24AmYzlkYWUzMzQtODkzMy00OTFiLWIzYTMtN2FiNDhjM2IyN2Jk&hl=en&authkey=COrG4NkM

