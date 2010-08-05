==================
NeuroPipe Tutorial
==================



:author: Mason Simon
:email: mgsimon@princeton.edu



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

  $ command-to-run

- Files will be written like this: *path/to/filename.ext*.
- Text that must be copied exactly as specified will be written inside of double quotes, like this: "text to copy".

 

Architecture of NeuroPipe
-------------------------

If your analysis were guaranteed to be identical for every subject, a set of analysis scripts, parameterized by subject id, would satisfy your needs; you would just run the analysis scripts for each subject. But if one subject differed from the others - say, they had to get out of the scanner, which cut a run short - then your analysis scripts would require conditional logic to deal with this, and other non-standard subjects. At the other extreme, if you made a copy of your analysis scripts for each subject, it would be simple to accomodate a non-standard subject by tweaking their scripts - independent of the rest. But, would complicate making a change in the analysis for subject, because you would have to edit the appropriate scripts for each subject.

NeuroPipe optimizes for both of these cases. Here's how: You make whatever scripts and files are necessary to analyze an ideal subject, then use them as a template that new subjects will be based on. This template is stored in the *subject-template* directory of your project. The files in this template are split into two types: those that may vary between subjects, and those that won't. The ones that may vary go into *subject-template/copy*, and they will be copied into each new subject's directory. The ones that won't vary go into *subject-template/link*, and they will be symlinked into each new subject's directory; that means that changing a linked files in any subject's directory will immediately change that file in all subject's directories. If you have a non-standard subject, you change the (copied) files within that subject's directory, and other subjects are unaffected. If you need to change the analysis for every subject, you change the linked files in the template, and the change is reflected in each subject's (linked) analysis scripts.



Installing NeuroPipe
--------------------

Requirements:

- unix-based computer (use rondo if you're at princeton)
- BXH XCEDE tools (already installed on rondo)
- FSL (already installed on rondo)


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

That command makes a rich folder structure at *ppa-hunt* for you to build your project in. Move into that directory and look around::

  $ cd ppa-hunt
  $ ls

You should see at least a *README.txt* file, a command called *scaffold*, a file called *protocol.txt*, and a directory called *subject-template*. Start by reading *README.txt*::

  $ less README.txt

The first instruction it has for us in the Getting Started section is to open *protocol.txt* and follow its instructions. Hit "q" to quit out of *README.txt*, then open *protocol.txt*::

  $ less protocol.txt

It says we should fill it in with details on the data collection protocol. We'll just download a *protocol.txt* file that describes the ppa-hunt data you're about to analyze. Hit "q" to quit out of *protocol.txt*, then run these commands::

  $ rm protocol.txt
  $ wget http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/protocol.txt

Read that newly downloaded *protocol.txt*::

  $ less protocol.txt

Hit "q", and open *README.txt* again::

  $ less README.txt

The next instruction it gives is to open *subject-template/copy/run-order.txt*. Hit "q", then read that file::

  $ less subject-template/copy/run-order.txt

As with *protocol.txt*, a *run-order.txt* file has already been prepared for you. Download that file, and put it where *README.txt* says::

  $ curl http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/run-order.txt > subject-template/copy/run-order.txt

Open *README.txt* one last time::

  $ less README.txt

It says the next step is to collect data for a subject. Lucky you, that's already been done, so skip that step. The final instruction is to run the command *./scaffold SUBJECT_ID*, with a real subject ID inserted in place of "SUBJECT_ID".


Setting up a subject to analyze
===============================

Our subject ID is "0608101_conatt02", so run this command::

  $ ./scaffold 0608101_conatt02

*scaffold* tells you that it made a subject directory at *subjects/0608101_conatt02* and that you should read the README.txt file there if this is your first time setting up a subject. Move into the subject's directory, and do what it says::

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

It says that we should proceed by doing various transformations on the data, and then running a quality assurance tool to make sure the data is usable. The transformations make the data more palatable to FSL_, which we will use for analysis. As *README.txt* says, you do all that with the command *analyze.sh*. Before running that, let's take a look at what it does::

  $ less analyze.sh

.. _FSL: http://www.fmrib.ox.ac.uk/fsl/

Look at the body of the script, and you'll see that it just calls another script, *prep.sh*. Hit "q" to quit reading *analyze.sh* and read *prep.sh*::

  $ less prep.sh

*prep.sh* calls three other scripts: one to do those transformations on the data, one to run the quality assurance tools, and one called *render-fsf-templates.sh*. Don't worry about that last one for now--we'll cover it later. If you'd like, you can open up those first two scripts to see in detail what they do. Otherwise, press on::

  $ ./analyze.sh

Once *analyze.sh* completes, look around *data/nifti*::

  $ ls data/nifti

There should be a pair of .bxh/.nii.gz files for each pulse sequence listed in *run-order.txt*, excluding the sequences called ERROR_RUN. Open the .nii.gz files with FSLView_, if you'd like, using a command like this::

  $ fslview data/nifti/0608101_conatt02_t1_mprage_sag01.nii.gz

.. _FSLView: http://www.fmrib.ox.ac.uk/fsl/fslview/index.html

There's also a new folder at *data/qa*. Peek in and you'll see a ton of files. These are organized by an HTML file at *data/qa/index.html*. Open it with this command::

  $ firefox data/qa/index.html

Use the "(What's this?)" links to figure out what all the diagnostics mean. When then diagnostics have convinced you that there are no quality issues with this data (such as lots of motion) that would make it uninterpretable, close firefox.



GLM analysis with FEAT
======================

Now that you've got some data, and know its quality is sufficient for analysis, it's time to do an analysis. We'll use FSL's FEAT to perform a GLM-based analysis. take a look at `FEAT's manual`_ to learn more about FEAT and GLM analysis in general.

.. _FEAT's manual: http://www.fmrib.ox.ac.uk/fsl/feat5/index.html

To set the parameters of the analysis, you must know the experimental design. Open *protocol.txt* in the project directory and read it::

  $ less ../../protocol.txt

Now launch FEAT::

  $ Feat &

It opens to the Data tab. 


The Data tab
------------

Click "Select 4D data" and select the file *data/nifti/localizer01.nii.gz*. Set "Output directory" to *analysis/firstlevel/localizer_hrf*. FEAT should have detected "Total volumes" as 244, but it may have mis-detected "TR (s)" as 3.0; if so, change that to 1.5. Because *protocol.txt* indicated there were 6s of disdaqs, and TR length is 1.5s, set "Delete volumes" to 4. Set "High pass filter cutoff (s)" to 128.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-data.png

Go to the Pre-stats tab.


The Pre-stats tab
-----------------

Change "Slice timing correction" to "Interleaved (0,2,4 ...". Leave the rest of the settings at their defaults.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-pre-stats.png

Go to the Stats tab.


The Stats tab
-------------

Check "Add motion parameters to model". Now we must use the description of the experimental design from *protocol.txt* to define regressors for our GLM. *protocol.txt* tells us that blocks consisted of 12 trials, each 1.5s long, with 12s rest between blocks, and 6s rest at the start to let the scanner settle down. That 6s at the start was taken care of in the Data tab, so we have a design that looks like Scene, rest, Face, rest, Scene, rest, ...

We will specify this design precisely using text files in FEAT's 3-column format: we make 1 text file per regressor, each with one line per period of time belonging to that regressor. Each line has 3 numbers, separated by whitespace. The first number indicates the onset time in seconds of the period. The second number indicates the duration of the period. The third number indicates the height of the regressor during the period; always set this to 1 unless you know what you're doing. See `FEAT's documentation`_ for more details.

.. _FEAT's documentation: http://www.fmrib.ox.ac.uk/fsl/feat5/detail.html#stats

In your own projects, you should make these files automatically based on the code that runs your experiment. For that reason, I've generated the 3-column files for you. Make a directory to put them in, then download the files::

  $ mkdir design
  $ curl http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/scene.txt >design/scene.txt
  $ curl http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/face.txt >design/face.txt

Click the "Full model setup" button. Set EV name to "scene". FSL calls regressors EV's, short for Explanatory Variables. Set "Basic shape" to "Custom (3 column format)" and select *design/scene.txt*. That file on its own describes a square wave, but to account for the shape of the BOLD response, we convolve it with another function. Set "Convolution" to "Double-Gamma HRF". Now we set up the face regressor. Set "Number of original EVs" to 2, then click tab 2.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-stats-ev1.png

Set EV name to "face". Set "Basic shape" to "Custom (3 column format)" and select *design/face.txt*. Change Convolution to Double-Gamma HRF, like we did for the scene regressor.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-stats-ev2.png

Now go to the Contrasts & F-tests tab. Increase "Contrasts" to 4. We'll make 1 contrast to show the main effect of the face regressor, one for the scene regressor, 1 to show where the scene regressor is greater than the face regressor, and one to show where the face regressor is greater:

* Set the 1st row's title to "scene", it's "EV1" value to 1, and it's "EV2" value to 0.
* Set the 2nd row's title to "face", it's "EV1" value to 0, and it's "EV2" value to 1.
* Set the 3rd row's title to "scene>face", it's "EV1" value to 1, and it's "EV2" value to -1.
* Set the 4th row's title to "face>scene", it's "EV1" value to -1, and it's "EV2" value to 1.

.. image:: http://github.com/mason-work/neuropipe/raw/master/doc/tutorial/feat-stats-contrasts-and-f-tests.png

Close that window, and FEAT should show you a graph of your model. If it doesn't look like the one below, check you followed the instructions correctly.

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

Now let's perform this analysis on a new subject. FEAT records all of the parameters of analyses you run with it in a file called *design.fsf* in its output directory. Our approach will be to take that file, replace any subject-specific settings with placeholders, and then for each new subject, substitute in appropriate values for the placeholders. Start by copying the *design.fsf* file for the analysis we just ran to a more central location::

  $ mv analysis/firstlevel/localizer_hrf.feat/design.fsf fsf/localizer_hrf.fsf

Now, open *fsf/localizer_hrf.fsf* in your favorite text editor. If you don't have a favorite, try this::

  $ nedit fsf/localizer_hrf.fsf

Make the following replacements:
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", replace all of the text inside the quotes with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set feat_files(1)", replace all of the text inside the quotes with "<?= $DATA_FILE_PREFIX ?>"
  #. on the line starting with "set initial_highres_files(1) ", replace all of the text inside the quotes with "<?= $INITIAL_HIGHRES_FILE ?>"
  #. on the line starting with "set highres_files(1)", replace all of the text inside the quotes with "<?= $HIGHRES_FILE ?>"

Save that file as *fsf/localizer_hrf.fsf.template*. To make it available in new subject directories, do this::

  $ cp fsf/localizer_hrf.fsf.template ../../subject-template/copy/fsf/

Now we have a template. To use it, we'll need a script that fills it in appropriately for each subject. This filling-in process is called rendering, and a script that does most of the work for you has already been provided at *scripts/render-fsf-templates.sh*. Open that in your text editor::

  $ nedit scripts/render-fsf-templates.sh

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

The command *feat* runs FEAT, without the graphical interface.

To make this script available in new subject directories, do this::

  $ cp hrf.sh ../../subject-template/link/

The *subject-template/link* directory holds files that should be identical in each subject's directory. Any file in that directory will be linked into each new subject's directory, which means that when any one of the linked files is changed in one subject's directory (or in *subject-template/link*), the change is immediately reflected in all the other links to that file.

Open *analyze.sh* in your text editor::

  $ nedit analyze.sh

After the line that runs *prep.sh*, add this line::
  
  bash hrf.sh

*analyze.sh* is linked to *subject-template/link/analyze.sh*, so the change you just made to it will be present in all other subject directories, as well as any changes you make to it in the future. Let's test this all out on a new subject. Assuming you're in subjects/0608101_conatt02, run these commands::

  $ cd ../../
  $ ./scaffold 0608102_conatt02.
  $ cd 0608102_conatt02
  $ curl http://www.princeton.edu/ntblab/resources/0608102_conatt02.tar.gz > data/raw.tar.gz
  $ ./analyze.sh

FEAT should now be churning away on the new data.
