==================
NeuroPipe Tutorial
==================



:author: Mason Simon
:email: mgsimon@princeton.edu



.. contents::



----------------------------------------------
Chapter 1 - HRF analysis of block design study
----------------------------------------------


Introduction
============

NeuroPipe is a framework for reproducible fMRI analysis projects with FSL. It's designed for group (across-subjects) analyses built on top of within-subjects analyses that are mainly identical. If this (or a subset of it) describes your project, NeuroPipe will help you implement your analyses and run them with a single command. This simplifies debugging, by letting you quickly make a fix and test it. And, it lets others re-run your analysis to verify your work is correct, or to build upon your project once you've finished it.

This tutorial walks you through using NeuroPipe for a within-subjects analysis on one subject, repeating that analysis for a second subject, and then running a group analysis across both of these subjects. For our example analysis, we fit a GLM to data collected while subjects viewed blocks of house images and face images, in order to locate the parahippocampal place area (PPA) in these subjects.


Prerequisites
-------------

NeuroPipe is built with UNIX commands and BASH scripts. If you're unfamiliar with those, this tutorial may confuse you. Invest some time into learning UNIX and shell scripting; it will yield good returns. Try starting with `Unix Third Edition: Visual Quickstart Guide`_, which you can read for free online if you're at Princeton.

.. _`Unix Third Edition: Visual Quickstart Guide`: http://proquest.safaribooksonline.com/0321442458 

You should be ok if you understand:

- how to run programs from the UNIX command line,
- how to move around the directory tree with *cd*,
- relative pathnames,
- symbolic links.

In addition to basic familiarity with the UNIX command line, you'll need access to a UNIX-based computer (Mac OSX or any flavor of Linux should work), with git_, `BXH XCEDE tools`_, and FSL_ installed. If you're at Princeton, use rondo_, which has all the necessary tools installed.

.. _git: http://git-scm.com/
.. _`BXH XCEDE tools`: http://nbirn.net/tools/bxh_tools/index.shtm
.. _FSL: http://www.fmrib.ox.ac.uk/fsl/
.. _rondo: http://cluster-wiki.pni.princeton.edu/dokuwiki/

In this tutorial, you use git to track changes to the example project. A full explanation of git and version control systems is the scope of the tutorial, so if you're unfamiliar with those, read chapters 1 and 2 of `Pro Git`_.

.. _`Pro Git`: http://progit.org/book/

To access the data that you'll analyze in this tutorial, email ntblab@gmail.com and request instructions.


Conventions used in this tutorial
---------------------------------

- Text that must be copied exactly is written between double quotes, like this: "text to copy".
- Commands to execute on the command line look like this::

  $ command-to-run

- Each section ends with a summary of commands used. Many of these commands are interactive (like using a text editor), so you can't complete the tutorial by just copy-and-pasting the summary sections. They're intended as a quick reference when you adapt the tutorial's methods to your own projects.
- Files are written like this: *path/to/filename.ext*.
- Absolute paths begin with "~/" to indicate the directory containing your project folder.
- At the beginning of each section, and after changing directory, are reminders of what directory you're in:

.. admonition:: you are here

   ~/ppa-hunt/subjects/
 

Architecture of NeuroPipe
-------------------------

Before using NeuroPipe, you should understand how it's structured and why.

Imagine your experiment needed no redesigns, your equipment never malfunctioned, and no subject moved, fell asleep, or didn't respond, etc... With the resulting data, your analysis pipeline could be blind to which subject it was analyzing; just throw some data in and it would do the same process.

But, if one subject differed from the others--say, they coughed during a run, leaving half the data usable--then your pipeline would require conditional logic to deal with this one--perhaps a different model specification, in this case. The complexity of the pipeline would grow with each non-standard subject.

At some point, it would become simpler to duplicate the pipeline for each subject and modify each copy as necessary. Imagine you do so, but then want a new statistical analysis for each subject. To accomplish that, you must now change each pipeline copy--a waste of time and likely source of bugs. The problem was caused by duplicating too much.

NeuroPipe provides the flexibility to analyze non-standard subjects, while minimizing duplication, by making you specify which parts of your pipeline may vary between subjects and which wont. You make whatever scripts and files are necessary to analyze an ideal subject and then use those as a basis for each new subject's pipeline. This is called the prototype and it's stored in the *prototype* directory of your project. To analyze a new subject, you'll use a command called *scaffold*, which creates a folder for the subject's pipeline based on what's in *prototype*. Files that may vary between subjects go into *prototype/copy*, and *scaffold* copies them into each new subject's directory. Files that won't vary go into *prototype/link*, and *scaffold* symlinks them into each new subject's directory; that means that changing a linked file in any subject's directory will immediately change that file in all subject's directories. If you have a non-standard subject, after scaffolding them, you change the appropriate (copied) files within that subject's directory, and other subjects are unaffected. If you must change the analysis for every subject, change the linked files in *prototype/link*, and the change is reflected in the corresponding files in each subject directory.

The workflow is to::

 1. develop your analysis pipeline for one subject,
 2. generalize that pipeline and divide the scripts into those that may vary between subjects and those that won't,
 3. use that prototype to scaffold new subjects,
 4. modify the new subjects's pipelines as necessary.

This architecture is diagrammed in the PDF here_.

.. _here: http://docs.google.com/viewer?url=http%3A%2F%2Fgithub.com%2Fntblab%2Fneuropipe-support%2Fraw%2Frc-0.2%2Fdoc%2Farchitecture.pdf


Setting up your NeuroPipe project
=================================

.. admonition:: you are here

   ~/

NeuroPipe is a sort of skeleton for fMRI analysis projects using FSL. To work with it, you download that skeleton, then flesh it out.

First, log in to your UNIX terminal. If you're at Princeton, that means log in to rondo; look at `the access page on the rondo wiki`_ if you're not sure how.

.. _`the access page on the rondo wiki`: http://cluster-wiki.pni.princeton.edu/dokuwiki/wiki:access

We'll use git to grab the latest copy of NeuroPipe. But before that, configure git with your current name, email, and text editor of choice (if you haven't already)::

  $ git config --global user.name "YOUR NAME HERE"
  $ git config --global user.email "YOUR_EMAIL@HERE.COM"
  $ git config --global core.editor nano

Now, using git, download NeuroPipe into a folder called *ppa-hunt*, and set it up::

  $ git clone http://github.com/ntblab/neuropipe.git ppa-hunt
  $ cd ppa-hunt
  $ git checkout -b ppa-hunt origin/rc-0.2

Look around::

  $ ls

.. admonition:: you are here

   ~/ppa-hunt

You should see a *README.txt* file, a command called *scaffold*, a file called *protocol.txt*, and a directory called *prototype*. Start by reading *README.txt*::

  $ less README.txt

The first instruction in the Getting Started section is to open *protocol.txt* and follow its instructions. Hit "q" to quit *README.txt*, then open *protocol.txt*::

  $ less protocol.txt

It says to fill it in with details on the data collection protocol. When working on your own project, be specific when filling out the protocol information, so anyone looking through your data has a clear idea of what happened during the experiment. For now, we'll just download a *protocol.txt* file that describes the ppa-hunt data you're about to analyze. Hit "q" to quit out of *protocol.txt*, then run these commands::

  $ rm protocol.txt
  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/protocol.txt > protocol.txt

Read that newly downloaded *protocol.txt*::

  $ less protocol.txt

Hit "q", and open *README.txt* again::

  $ less README.txt

The next instruction is to open *prototype/copy/run-order.txt*. Hit "q", then read that file::

  $ less prototype/copy/run-order.txt

As with *protocol.txt*, a *run-order.txt* file is already made for you. Download that file, and put it where *README.txt* says::

  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831101_confba02_run-order.txt > prototype/copy/run-order.txt

Open this new *run-order.txt* to see what it's like now::

  $ less prototype/copy/run-order.txt

Most runs are marked as "ERROR_RUN" so that only the runs relevant to this tutorial remain.

Quit *run-order.txt* with "q", and open *README.txt* one last time::

  $ less README.txt

It says the next step is to collect data for a subject. That's already been done, so skip that step. The final instruction is to run the command *./scaffold SUBJECT_ID*, with a real subject ID inserted in place of "SUBJECT_ID". We'll do that next.

**Summary**::

  $ git clone http://github.com/ntblab/neuropipe.git ppa-hunt
  $ cd ppa-hunt
  $ git checkout -b ppa-hunt origin/rc-0.2
  $ ls
  $ less README.txt
  $ less protocol.txt
  $ rm protocol.txt
  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/protocol.txt > protocol.txt
  $ less protocol.txt
  $ less README.txt
  $ less prototype/copy/run-order.txt
  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/run-order.txt > prototype/copy/run-order.txt
  $ less prototype/copy/run-order.txt
  $ less README.txt


Analyzing a subject
===================

We'll start by analyzing a single subject.


Setting up
----------

.. admonition:: you are here

   ~/ppa-hunt

Our subject ID is "0831101_confba02", so run this command::

  $ ./scaffold 0831101_confba02

*scaffold* tells you that it made a subject directory at *subjects/0831101_confba02* and that you should read the *README.txt* file there if this is your first time setting up a subject. Move into the subject's directory, and do what it says::

  $ cd subjects/0831101_confba02
  $ less README.txt

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

This *README.txt* says your first step is to get some DICOM data and put it in a Gzipped TAR archive at *data/raw.tar.gz*. Like I mentioned, the data has already been collected. It's even TAR-ed and Gzipped. Hit "q" to quit *README.txt* and get the data with this command (NOTE: you must be on rondo for this to work)::

  $ cp /exanet/ntb/packages/neuropipe/example_data/0831101_confba02.raw.tar.gz data/raw.tar.gz

It will prompt you to enter a password; email ntblab@gmail.com to request access to this data if you don't have it. NOTE: *cp* just copies files, and here we've directed it to copy data that was prepared for this tutorial; it doesn't work in general to retrieve data after you've done a scan. On rondo at Princeton, you can use *~/prototype/link/scripts/retrieve-data-from-sun.sh* (which appears at *~/subjects/SUBJ/scripts/retrieve-data-from-sun.sh*) to get your data, as long as your subject's folder name matches the subject ID used during for your scan session.

**Summary**::

  $ ./scaffold 0831101_confba02
  $ cd subjects/0831101_confba02
  $ less README.txt
  $ cp /exanet/ntb/packages/neuropipe/example_data/0831101_confba02.raw.tar.gz data/raw.tar.gz


Preparing your data for analysis
--------------------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Open *README.txt* again::

  $ less README.txt

We already set up *run-order.txt*, and put it in *prototype/copy/*. That directory is special. Any file or folder in it will be copied into each new subject directory that's created by *scaffold*. To check that *run-order.txt* came through all right, hit "q" to get out of *README.txt*, and run this command::

$ less run-order.txt

You should see that it's identical to the one we downloaded before. Hit "q", then open *README.txt* one last time::

$ less README.txt

It says that we should proceed by doing various transformations on the data, and then running a quality assurance tool to make sure the data is usable. The transformations make the data more palatable to FSL_, which we will use for analysis. As *README.txt* says, you do all that with the command *analyze.sh*. Before running that, see what it does::

$ less analyze.sh

.. _FSL: http://www.fmrib.ox.ac.uk/fsl/

Look at the body of the script, and notice it just runs another script: *prep.sh*. Hit "q" to quit *analyze.sh* and read *prep.sh*::

$ less prep.sh

*prep.sh* calls four other scripts: one to do those transformations on the data, one to run the quality assurance tools, one to perform some more transformations on the data, and one called *render-fsf-templates.sh*. Don't worry about that last one for now--we'll cover it later. If you'd like, open those first three scripts to see what they do. Otherwise, press on::

  $ ./analyze.sh

Once *analyze.sh* completes, look around *data/nifti*::

  $ ls data/nifti

There should be a pair of .bxh/.nii.gz files for each pulse sequence listed in *run-order.txt*, excluding the sequences called ERROR_RUN. Open the .nii.gz files with FSLView_, if you'd like, using a command like this::

$ fslview data/nifti/0831101_confba02_t1_mprage01.nii.gz

.. _FSLView: http://www.fmrib.ox.ac.uk/fsl/fslview/index.html

There's also a new folder at *data/qa*. Peek in and you'll see a ton of files. These are organized by an HTML file at *data/qa/index.html*. Open it with this command::

$ firefox data/qa/index.html

Use the "(What's this?)" links to figure out what all the diagnostics mean. When then diagnostics have convinced you that there are no quality issues with this data (such as lots of motion) that would make it uninterpretable, close firefox.

**Summary**::

  $ less README.txt
  $ less run-order.txt
  $ less README.txt
  $ less analyze.sh
  $ less prep.sh
  $ ./analyze.sh
  $ ls data/nifti
  $ fslview data/nifti/0831101_confba02_t1_mprage01.nii.gz
  $ firefox data/qa/index.html


GLM analysis with FEAT (first-level)
------------------------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Now that you have data, and of adequate quality, it's time to do an analysis. We'll use FSL's FEAT to perform a GLM-based analysis. If GLM analysis or FEAT is new to you, read `FEAT's manual`_ to learn more about them. If any of the steps seem mysterious to you, hover your mouse over the relevant part of FEAT and a tooltip will appear describing that part in detail.

.. _FEAT's manual: http://www.fmrib.ox.ac.uk/fsl/feat5/index.html

To set the parameters of the analysis, you must know the experimental design. Open *protocol.txt* in the project directory and read it::

 $ less ../../protocol.txt

Now launch FEAT::

 $ Feat &

It opens to the Data tab.

**Summary**::

 $ less ../../protocol.txt
 $ Feat &


The Data tab
''''''''''''

.. admonition:: you are here

~/ppa-hunt/subjects/0831101_confba02

Click "Select 4D data" and select the file *data/nifti/0831101_confba02_localizer01.nii.gz*; FEAT will analyze this data. Set "Output directory" to *analysis/firstlevel/localizer_hrf_01*; FEAT will put the results of its analysis in this folder, but with ".feat" appended, or "+.feat" appended if this is the second analysis with this name that you've run. FEAT should have detected "Total volumes" as 221, but it may have mis-detected "TR (s)" as 3.0; if so, change that to 1.5, because this experiment had a TR length of 1.5 seconds. Because *protocol.txt* indicated there were 6 seconds of disdaqs (volumes of data at the start of the run that are discarded because the scanner needs a few seconds to settle down), and TR length is 1.5s, set "Delete volumes" to 4. Set "High pass filter cutoff (s)" to 128 to remove slow drifts from your signal.

.. image:: https://github.com/ntblab/neuropipe-support/doc/tutorial/feat-data.png

Go to the Pre-stats tab.


The Pre-stats tab
'''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Change "Slice timing correction" to "Interleaved (0,2,4 ...", because slices were collected in this interleaved pattern. Leave the rest of the settings at their defaults.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/feat-pre-stats.png

Go to the Stats tab.


The Stats tab
'''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Check "Add motion parameters to model"; this makes regressors from estimates of the subject's motion, which hopefully absorb variance in the signal due to transient motion. To account for the variance in the signal due to the experimental manipulation, we define regressors based on the design, as described in *protocol.txt*. *protocol.txt* says that blocks consisted of 12 trials, each 1.5s long, with 12s rest between blocks, and 6s rest at the start to let the scanner settle down. That 6s at the start was taken care of in the Data tab, so we have a design that looks like House, rest, Face, rest, House, rest, ...

We will specify this design using text files in FEAT's 3-column format: we make 1 text file per regressor, each with one line per period of time belonging to that regressor. Each line has 3 numbers, separated by whitespace. The first number indicates the onset time in seconds of the period. The second number indicates the duration of the period. The third number indicates the height of the regressor during the period; always set this to 1 unless you know what you're doing. See `FEAT's documentation`_ for more details.

.. _FEAT's documentation: http://www.fmrib.ox.ac.uk/fsl/feat5/detail.html#stats

These design files are provided for you. Make a directory to put them in, then download the files::

 $ mkdir design
 $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831101_confba02_house.txt >design/house.txt
 $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831101_confba02_face.txt >design/face.txt

Examine each of these files and refer to *protocol.txt* as necessary::

 $ less design/house.txt
 $ less design/face.txt

When making these design files for your own projects, do not use a Windows machine or you will likely have `problems with line endings`_.

.. _`problems with line endings`: http://en.wikipedia.org/wiki/Newline#Common_problems

To use these files to specify the design, click the "Full model setup" button. Set EV name to "house". FSL calls regressors EV's, short for Explanatory Variables. Set "Basic shape" to "Custom (3 column format)" and select *design/house.txt*. That file on its own describes a square wave; to account for the shape of the BOLD response, we convolve it with another function that models the hemodynamic response to a stimulus. Set "Convolution" to "Double-Gamma HRF". Now to set up the face regressor set "Number of original EVs" to 2 and click to tab 2.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/feat-stats-ev1.png

Set EV name to "face". Set "Basic shape" to "Custom (3 column format)" and select *design/face.txt*. Change "Convolution" to "Double-Gamma HRF", like we did for the house regressor.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/feat-stats-ev2.png

Now go to the "Contrasts & F-tests" tab. Increase "Contrasts" to 4. There is now a matrix of number fields with a row for each contrast and a column for each EV. You specify a contrast as a linear combination of the parameter estimates on each regressor. We'll make one contrast to show the main effect of the face regressor, one to show the main effect of the house regressor, one to show where the house regressor is greater than the face regressor, and one to show where the face regressor is greater:

* Set the 1st row's title to "face", it's "EV1" value to 1, and it's "EV2" value to 0. * Set the 2nd row's title to "house", it's "EV1" value to 0, and it's "EV2" value to 1. * Set the 3rd row's title to "face>house", it's "EV1" value to 1, and it's "EV2" value to -1. * Set the 4th row's title to "house>face", it's "EV1" value to -1, and it's "EV2" value to 1.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/feat-stats-contrasts-and-f-tests.png

Close that window, and FEAT shows you a graph of your model. If it's different from the one below, check you followed the instructions correctly.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/feat-model-graph.png

Go to the Registration tab.

**Summary**::

$ mkdir design
$ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831101_confba02_house.txt >design/house.txt
$ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831101_confba02_face.txt >design/face.txt
$ less design/house.txt
$ less design/face.txt


The Registration tab
''''''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Different subjects have different shaped brains, and may have been in different positions in the scanner. To compare the data collected from different subjects, for each subject we compute the transformation that best moves and warps their data to match a standard brain, apply those transformations, then compare each subject in this "standard space". This Registration tab is where we set the parameters used to compute the transformation; we won't actually apply the transformation until we get to group analysis.

FEAT should already have a "Standard space" image selected; leave it with the default, but change the drop-down menu from "Normal search" to "Full search", or this subject's brain will be misregistered. Check "Initial structural image", and select the file *subjects/0831101_confba02/data/nifti/0831101_confba02_t1_flash01.nii.gz*. Change the drop-down menu from "Normal search" to "No search," and change the other menu from "7 DOF" to "3 DOF (translation only)." Check "Main structural image", and select the file *subjects/0831101_confba02/data/nifti/0831101_confba02_t1_mprage01.nii.gz*.

The subject's functional data is first registered to the initial structural image, then that is registered to the main structural image, which is then registered to the standard space image. All this indirection is necessary because registration can fail, and it's more likely to fail if you try to go directly from the functional data to standard space.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/feat-registration.png

That's it! Hit Go. A webpage should open in your browser showing FEAT's progress. Once it's done, this webpage provides a useful summary of the analysis you just ran with FEAT. Later, we'll make a webpage for this subject to gather information like this FEAT report, the QA results, and plots summarizing this subject's data. But for now, let's continue hunting the PPA.


Finding the PPA
---------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Launch FSLView::

  $ fslview

Click File>Open... and select *analysis/firstlevel/localizer_hrf.feat/mean_func.nii.gz*; this is an image of the mean signal intensity at each voxel over the course of the run. We use it as a background to overlay a contrast image on. Click File>Add... *analysis/firstlevel/localizer_hrf.feat/stats/zstat4.nii.gz*. *zstat3.nii.gz* is an image of z-statistics for the house>face contrast being different from 0, so high intensity values in a voxel indicate that the house regressor caught much more of the variance in fMRI signal at that voxel than the face regressor. To find the PPA, we'll look for regions with really high values in *zstat4.nii.gz*. To include only these regions in the overlay, set the Min threshold at the top of FSLView to something like 8, then click around in the brain to see what regions had contrast z-stats at that threshold or above. Look for a bilateral pair of regions with zstat's at a high threshold, around the middle of the brain; that'll be the PPA.


Repeating the analysis for a second run
========================================

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02
   
Now that you have analyzed one run of this subject's data, it's time to repeat the analysis on a second run. In many experiments, subjects will perform the same task in two identical runs so they have a bit of a break during the scanning session, or because different stimuli are counterbalanced across the scan session. The two runs can then be combined in a second-level analysis. This time around, we can do it more automatically. FEAT recorded all parameters of the analysis you just ran, in a file called *design.fsf* in its output directory, which was *analysis/firstlevel/localizer_hrf_01.feat/*. Our approach is to take that file, replace run-specific settings with placeholders, then for each new run, automatically substitute appropriate values for the placeholders, and run FEAT with the resulting file. 

Templating the fsf file
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Start by copying the *design.fsf* file for the analysis we just ran to *fsf*, and give it a ".template" extension::

  $ cp analysis/firstlevel/localizer_hrf_01.feat/design.fsf fsf/localizer_hrf.fsf.template

We'll keep fsf files and their templates in this *fsf* folder. Now, open *fsf/localizer_hrf.fsf.template* in your favorite text editor. If you don't have a favorite, try this::

  $ nano fsf/localizer_hrf.fsf.template

Make the following replacements and save the file. Be sure to include the spaces after "<?=" and before "?>". ::
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", replace all of the text inside the quotes with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set feat_files(1)", replace all of the text inside the quotes with "<?= $DATA_FILE_PREFIX ?>"
  #. on the line starting with "set initial_highres_files(1) ", replace all of the text inside the quotes with "<?= $INITIAL_HIGHRES_FILE ?>"
  #. on the line starting with "set highres_files(1)", replace all of the text inside the quotes with "<?= $HIGHRES_FILE ?>"

Those bits you replaced with placeholders are the parameters that must change when analyzing a different run, a new subject, or using a different computer. After saving the file, copy it to the prototype so it's available for future subjects::

  $ cp fsf/localizer_hrf.fsf.template ../../prototype/copy/fsf/

Recall that the *prototype/copy* holds files that should initially be the same, but may need to vary between subjects. We put the fsf file there because it may need to be tweaked for future subjects - to fix registration problems, for instance.

**Summary**::

  $ cp analysis/firstlevel/localizer_hrf_01.feat/design.fsf fsf/localizer_hrf.fsf.template
  $ nano fsf/localizer_hrf.fsf.template
  $ cp fsf/localizer_hrf.fsf.template ../../prototype/copy/fsf/
 

Rendering the template
----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Now, we have a template fsf file. To use that template, we need a script that fills it in, appropriately, for each run and for each subject. This filling-in process is called rendering, and a script that does most of the work is provided at *scripts/render-fsf-templates.sh*. Open that in your text editor::

$ nano scripts/render-fsf-templates.sh

It consists of a function called render_firstlevel, which we'll use to render the localizer template. Copy these lines as-is onto the end of that file, then save it::

  render_firstlevel $FSF_DIR/localizer_hrf.fsf.template \
                    $FIRSTLEVEL_DIR/localizer_hrf_01.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_localizer01 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage01.nii.gz \
                    > $FSF_DIR/localizer_hrf_01.fsf

  render_firstlevel $FSF_DIR/localizer_hrf.fsf.template \
                    $FIRSTLEVEL_DIR/localizer_hrf_02.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_localizer02 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage01.nii.gz \
                    > $FSF_DIR/localizer_hrf_02.fsf
                    
That hunk of code calls the function render_firstlevel, passing it the values to substitute for the template's placeholders. Each chunk of code will create a new design.fsf file, one for each localizer run. This will be useful when analyzing the next subject's data. The values in this script use a bunch of completely-uppercase variables, which are defined in *globals.sh*.  Examine *globals.sh*::

  $ less globals.sh

*scripts/convert-and-wrap-raw-data.sh* needs to know where to look for the subject's raw data, and where to put the converted and wrapped data. *scripts/qa-wrapped-data.sh* needs to know where that wrapped data was put. To avoid hardcoding that information into each script, those locations are defined as variables in *globals.sh*, which each script then loads. By building the call to render_firstlevel with those variables, we won't need to modify it for each subject, and if you ever change the structure of your subject directory, all you must do is modify *globals.sh* to reflect the changes.

**Summary**::

  $ nano scripts/render-fsf-templates.sh
  $ less globals.sh
  
Automating the analysis
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

As we saw earlier, *prep.sh* already calls *render-fsf-templates.sh*. *analyze.sh* calls *prep.sh*, so to automate the analysis, all that remains is running *feat* on the rendered fsf file from a script that's called by *analyze.sh*. We'll make a new script called *localizer.sh* for that purpose. Make the script with this command::

  $ nano scripts/localizer.sh

Then fill it with this text::

  #!/bin/bash
  source globals.sh
  feat $FSF_DIR/localizer_hrf_01.fsf
  feat $FSF_DIR/localizer_hrf_02.fsf
  
The first line says that this is a BASH script. The second line loads variables from *globals.sh*. The the last two lines call *feat*, which runs FEAT without the graphical interface. The argument passed to *feat* is the path to the fsf file for it to use. Notice that the path is specified with a variable "$FSF_DIR", which is defined in *globals.sh*.

To make this script available in future subject directories, copy it to the prototype::

 $ cp scripts/localizer.sh ../../prototype/link/scripts

Remember, *prototype/link* holds files that should be identical in each subject's directory. Any file in that directory will be linked into each new subject's directory: when a linked file is changed in one subject's directory (or in *prototype/link*), the change is immediately reflected in all other links to that file.

Now that we have a script for running the GLM analysis, we'll call it from *analyze.sh* so that one command does the entire analysis. Open *analyze.sh* in your text editor::

 $ nano analyze.sh

After the line that runs *prep.sh*, add this line::

 bash scripts/localizer.sh

*analyze.sh* is linked to *~/prototype/link/analyze.sh*, so the change you just made will be reflected in *analyze.sh* in all current and future subject directories. Now we can test that it works. First, remove the finished analysis folder::

 $ rm -rf analysis/firstlevel/*

Then, run our newly updated analysis that deals with both localizer runs::

 $ ./analyze.sh

Feat should be churning away, and two webpages should open in your browser showing FEAT's progress. There should be one feat folder for each run in *analysis/firstlevel*.

**Summary**::

  $ nano scripts/localizer.sh
  $ cp scripts/localizer.sh ../../prototype/link/scripts
  $ nano analyze.sh
  $ rm -rf analysis/firstlevel/*
  $ ./analyze.sh

Collapsing across the two localizer runs
========================================

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Now that we have completed Feat analyses for the two localizer runs, it's time to combine the results of the two runs. We'll use FEAT again to run what it calls a "higher-level analysis", which combines the information from those "first-level" analyses that we just did. The process will be very similar to that in `GLM analysis with FEAT (first-level)`_. When running first-level analyses, we stored FEAT folders, scripts, and fsf files in the subjects's *analysis/firstlevel* folder; now that we're doing analyses that combine runs, we'll store all of those under *analysis/secondlevel*.


GLM analysis with FEAT (higher-level)
-------------------------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Launch FEAT::

  $ Feat &


The Data tab
''''''''''''

Change the drop-down in the top left from "First-level analysis" to "Higher-level analysis". This will change the stuff you see below. Set "Number of inputs" to 2, because we're combining 2 run analyses, then click "Select FEAT directories". For the first directory, select *analysis/firstlevel/localizer_hrf_01.feat*, and for the second, select *analysis/firstlevel/localizer_hrf_02.feat*. Set the output directory to *analysis/secondlevel/localizer_hrf*.

Go to the Stats tab.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/secondlevel-feat-data.png


The Stats tab
'''''''''''''

Click "Model setup wizard", leave it on the default option of "single group average", and click "Process". That's it! Hit "Go" to run the analysis.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/secondlevel-feat-stats.png


Finding the subject's PPA
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

When the analysis finishes, open FSLview::

  $ fslview &

Click File>Open Standard and accept the default. Click File>Add, and select *~/ppa-hunt/analysis/secondlevel/localizer_hrf.gfeat/cope4.feat/stats/zstat1.nii.gz*. 

**Summary**::

 $ Feat &
 $ fslview &
 
Templating the second-level analysis
------------------------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02
   
While we're here, we are also going to template the second-level analysis so we can have it ready for future subjects. This way we can do the entire analysis for a new subject in just a few commands. Start by copying the *design.fsf* file for the analysis we just ran to *fsf*, and give it a ".template" extension::

  $ cp analysis/secondlevel/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf_secondlevel.fsf.template

Now, open *fsf/localizer_hrf_secondlevel.fsf.template*::

  $ nano fsf/localizer_hrf_secondlevel.fsf.template

When we made a template fsf file for the within-subject analyses, we didn't have to change the structure of the template, only replace single lines with placeholders. But to template a higher-level fsf file, we'll need to repeat whole sections of the fsf file for each input run going into the group analysis. To accomplish this, we'll use PHP_ to render the templates, and write loops_ for those sections of the template that need repeating for each subject. You won't need to know PHP to follow the steps below, but if you're curious about what we're doing, read that page on loops.

.. _PHP: http://en.wikipedia.org/wiki/PHP
.. _loops: http://www.php.net/manual/en/control-structures.for.php

Make the following replacements and save the file. Be sure to include the spaces after each "<?=" and before each "?>".::
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", copy or write down the text inside the quotes, then replace it with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set fmri(npts)", replace the number at the end of the line with "<?= count($runs) ?>"
  #. on the line starting with "set fmri(multiple)", replace the number at the end of the line with "<?= count($runs) ?>"

Those were the parts of the template that won't vary with the number of subjects; now we template the parts that will, using loops. 

Find the line that says "# 4D AVW data or FEAT directory (1)". Replace it and the next 4 lines with::

  <?php for ($i=0; $i < count($runs); $i++) { ?>
  # 4D AVW data or FEAT directory (<?= $i+1 ?>)
  set feat_files(<?= $i+1 ?>) "<?= $SUBJ_DIR ?>/<?= $SUBJ ?>/analysis/firstlevel/<?= $runs[$i] ?>"

  <?php } ?>

Find the line that says "# Higher-level EV value for EV 1 and input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($runs)+1; $i++) { ?>
  # Higher-level EV value for EV 1 and input <?= $i ?> 
  set fmri(evg<?= $i ?>.1) 1

  <?php } ?>

Find the line that says "# Group membership for input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($runs)+1; $i++) { ?>
  # Group membership for input <?= $i ?> 
  set fmri(groupmem.<?= $i ?>) 1

  <?php } ?>

Save the file.

**Summary**::

  $ cp analysis/secondlevel/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf_secondlevel.fsf.template
  $ nano fsf/localizer_hrf_secondlevel.fsf.template


Automating the second-level analysis
-----------------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Now that we have a template for the second-level localizer analysis fsf file, all that's left is to render it and run FEAT on the rendered fsf file. Open up the *localizer.sh* script we made earlier with your text editor::

  $ nano scripts/localizer.sh

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Copy these lines into localizer.sh at the end::
  
  # Wait for two first-level analyses to finish
  scripts/wait-for-feat.sh $ANALYSIS_DIR/firstlevel/localizer_hrf_01.feat
  scripts/wait-for-feat.sh $ANALYSIS_DIR/firstlevel/localizer_hrf_02.feat
  
  STANDARD_BRAIN=/usr/share/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
  
  # This function defines variables needed to render higher-level fsf templates.
  function define_vars {
    output_dir=$1

    echo "
    <?php
    \$OUTPUT_DIR = '$output_dir';
    \$STANDARD_BRAIN = '$STANDARD_BRAIN';
    \$SUBJECTS_DIR = '$PROJECT_DIR/$SUBJECT_DIR';
    "

    echo '$subjects = array();'
    for subj in $ALL_SUBJECTS; do
      echo "array_push(\$subjects, '$subj');";
    done

    echo "
    ?>
    "
  }

  # Form a complete template by prepending variable definitions to the template,
  # then render it with PHP and run FEAT on the rendered fsf file.
  fsf_template=$FSF_DIR/localizer_hrf_secondlevel.fsf.template
  fsf_file=$FSF_DIR/localizer_hrf_secondlevel.fsf
  output_dir=analysis/secondlevel/localizer_hrf.gfeat
  define_vars $output_dir | cat - "$fsf_template" | php > "$fsf_file"
  feat "$fsf_file"

  popd > /dev/null  # return to whatever directory this script was run from

If the text following "STANDARD_BRAIN=" differs from what you copied out of the fsf file in the previous section, replace it with that text you copied.

Save and close the script, then run it to test that everything works::

  $ bash scripts/localizer.sh

A webpage should open in your browser showing FEAT's progress. Because we manually ran this analysis and put its output into *analysis/secondlevel/localizer_hrf.gfeat*, FEAT should have created a new directory at *analysis/secondlevel/localizer_hrf+.gfeat*, and should be showing you the analysis running in that directory.

**Summary**::

  $ nano scripts/localizer.sh
  $ bash scripts/localizer.sh

 
 Repeating the analysis for a new subject
======================================== 

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Congratulations on analyzing your first subject with NeuroPipe! Now, we'll do it again, but much of the work has already been done. First, move back into the project directory::

 $ cd ../../
 
Now, scaffold a new subject. This subject is 0831102_confba02::

 $ ./scaffold 0831102_confba02

Then, move into that subject's directory::

 $ cd subjects/0831102_confba02
 
This subject's stimuli order was slightly different. Instead of beginning with face images, their first set of stimuli were house images. They therefore have different face and house regressor files. They're provided for you already::

  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831102_confba02_house.txt > design/house.txt
  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831102_confba02_face.txt > design/face.txt

We already made a template for the localizer run that works for different subjects, edited scripts/render-fsf-templates.sh to make a unique design file for each run, and created localizer.sh to run the two Feat analyses. Because we already copied these files into *~/protoype*, these changes will be present in the new subject's directory. All that's left is to render the templates and then run the analysis! First, fill in the templates::

  $ scripts/render-fsf-templates.sh
  
Now you can see that there are two design files waiting to go in *fsf*::

  $ ls fsf

Get the subject's data (NOTE: you must be on rondo for this to work)::

  $ cp /exanet/ntb/packages/neuropipe/example_data/0831102_confba02.raw.tar.gz data/raw.tar.gz

As before, it will prompt you to enter a password; email ntblab@princeton.edu to request access to this data.

Now, analyze it::

  $ ./analyze.sh

FEAT should be churning away on the new data. Take some time to look over the QA for the new data, and check out the results of the Feat analyses.

**Summary**::
 
  $ cd ../../
  $ ./scaffold 0831102_confba02
  $ cd subjects/0831102_confba02
  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831102_confba02_house.txt > design/house.txt
  $ curl https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/0831102_confba02_face.txt > design/face.txt
  $ scripts/render-fsf-templates.sh
  $ ls fsf
  $ cp /exanet/ntb/packages/neuropipe/example_data/0831102_confba02.raw.tar.gz data/raw.tar.gz
  $ ./analyze.sh


Combining within-subjects analyses into a group analysis
========================================================

.. admonition:: you are here

   ~/ppa-hunt/subjects/0831101_confba02

Now that we've found the PPAs for two subjects individually, it's time to perform a group analysis to learn how reliable the PPA location is across these subjects. We'll use FEAT again to run what it calls a "higher-level analysis", which takes the information from those "first-level" analyses that we just did. The process will be very similar to that in `GLM analysis with FEAT (first-level)`_. When running within-subjects analyses, we stored FEAT folders, scripts, and fsf files in the subjects's folders; now that we're doing group analyses, we'll store all of those under *~/group*.


GLM analysis with FEAT (higher-level)
-------------------------------------

Move up to the root project folder, then to the group folder::

  $ cd ../../
  $ cd group

.. admonition:: you are here

   ~/ppa-hunt/group

Launch FEAT::

  $ Feat &


The Data tab
''''''''''''

Change the drop-down in the top left from "First-level analysis" to "Higher-level analysis". This will change the stuff you see below. Set "Number of inputs" to 2, because we're combining 2 within-subjects analyses, then click "Select FEAT directories". For the first directory, select *~/ppa-hunt/subjects/0831101_confba02/analysis/secondlevel/localizer_hrf.gfeat*, and for the second, select *~/ppa-hunt/subjects/0831102_confba02/analysis/secondlevel/localizer_hrf.gfeat*. Set the output directory to *~/ppa-hunt/group/analysis/localizer_hrf*.

Go to the Stats tab.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/group-feat-data.png


The Stats tab
'''''''''''''

Click "Model setup wizard", leave it on the default option of "single group average", and click "Process". That's it! Hit "Go" to run the analysis.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.2/doc/tutorial/group-feat-stats.png


Finding the group's PPA
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/group

When the analysis finishes, open FSLview::

  $ fslview &

Click File>Open Standard and accept the default. Click File>Add, and select *~/ppa-hunt/group/analysis/localizer_hrf.gfeat/cope4.feat/stats/zstat1.nii.gz*. 

Automating the group analysis
=============================

To automate the group analysis to work without additional effort when new subjects are added, we follow the same sort of procedure we did for within-subjects analyses: take the fsf file created when we manually ran FEAT, turn it into a template, write a script to render that template appropriately, then write a script to run FEAT on the rendered fsf file.


Templating the group fsf file
-----------------------------

.. admonition:: you are here

   ~/ppa-hunt/group

Just like when we ran a second-level analysis on two localizer runs for each subject, to template a higher-level fsf file, we'll need to repeat whole sections of the fsf file for each input going into the group analysis. In this case, each input is a subject instead of a run. Like before, we'll use PHP_ to render the templates, and write loops_ for those sections of the template that need repeating for each subject.

Start by copying the *design.fsf* file for the group analysis we just ran to *~/group/fsf*, and give it a ".template" extension::

  $ cp analysis/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf_thirdlevel.fsf.template

Now, open *fsf/localizer_hrf_thirdlevel.fsf.template* in your favorite text editor::

  $ nano fsf/localizer_hrf_thirdlevel.fsf.template

Make the following replacements and save the file. Be sure to include the spaces after each "<?=" and before each "?>". ::
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", copy or write down the text inside the quotes, then replace it with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set fmri(npts)", replace the number at the end of the line with "<?= count($subjects) ?>"
  #. on the line starting with "set fmri(multiple)", replace the number at the end of the line with "<?= count($subjects) ?>"

Those were the parts of the template that won't vary with the number of subjects; now we template the parts that will, using loops. 

Find the line that says "# 4D AVW data or FEAT directory (1)". Replace it and the next 4 lines with::

  <?php for ($i=0; $i < count($subjects); $i++) { ?>
  # 4D AVW data or FEAT directory (<?= $i+1 ?>)
  set feat_files(<?= $i+1 ?>) "<?= $SUBJ_DIR ?>/<?= $subjects[$i] ?>/analysis/secondlevel/localizer_hrf.gfeat"

  <?php } ?>

Find the line that says "# Higher-level EV value for EV 1 and input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($subjects)+1; $i++) { ?>
  # Higher-level EV value for EV 1 and input <?= $i ?> 
  set fmri(evg<?= $i ?>.1) 1

  <?php } ?>

Find the line that says "# Group membership for input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($subjects)+1; $i++) { ?>
  # Group membership for input <?= $i ?> 
  set fmri(groupmem.<?= $i ?>) 1

  <?php } ?>

Save the file.

**Summary**::

  $ cp analysis/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf_thirdlevel.fsf.template
  $ nano fsf/localizer_hrf_thirdlevel.fsf.template 

Automating the group analysis
-----------------------------

.. admonition:: you are here

   ~/ppa-hunt/group

Now that we have a template for the group localizer analysis fsf file, all that's left is to render it and run FEAT on the rendered fsf file. Move up to the project directory and make a file in *scripts* called *group-localizer.sh* with your text editor::

  $ cd ..
  $ nano scripts/group-localizer.sh

.. admonition:: you are here

   ~/ppa-hunt

Copy these lines into *scripts/group-localizer.sh*::

  #!/bin/bash

  source globals.sh  # load project-wide settings

  STANDARD_BRAIN=/usr/share/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
  
  # This function defines variables needed to render higher-level fsf templates.
  function define_vars {
    output_dir=$1

    echo "
    <?php
    \$OUTPUT_DIR = '$output_dir';
    \$STANDARD_BRAIN = '$STANDARD_BRAIN';
    \$SUBJECTS_DIR = '$PROJECT_DIR/$SUBJECT_DIR';
    "

    echo '$subjects = array();'
    for subj in $ALL_SUBJECTS; do
      echo "array_push(\$subjects, '$subj');";
    done

    echo "
    ?>
    "
  }

  # Form a complete template by prepending variable definitions to the template,
  # then render it with PHP and run FEAT on the rendered fsf file.
  fsf_template=$GROUP_DIR/fsf/localizer_hrf_thirdlevel.fsf.template
  fsf_file=$GROUP_DIR/fsf/localizer_hrf_thirdlevel.fsf
  output_dir=$GROUP_DIR/analysis/localizer_hrf.gfeat
  define_vars $output_dir | cat - "$fsf_template" | php > "$fsf_file"
  feat "$fsf_file"

If the text following "STANDARD_BRAIN=" differs from what you copied out of the fsf file in the previous section, replace it with that text you copied.

Save and close the script, then run it to test that everything works::

  $ bash scripts/group-localizer.sh

A webpage should open in your browser showing FEAT's progress. Because we manually ran this analysis and put its output into *~/ppa-hunt/group/analysis/localizer_hrf.gfeat*, FEAT should have created a new directory at *~/ppa-hunt/group/analysis/localizer_hrf+.gfeat*, and be showing you the analysis running in that directory.

**Summary**::

  $ cd ../..
  $ nano scripts/group-localizer.sh
  $ bash scripts/group-localizer.sh


Automating the entire analysis
==============================

.. admonition:: you are here

   ~/ppa-hunt

Our goal was to run the entire analysis with a single command, to make it easy to reproduce. We're close. Open *analyze.sh* in your text editor::

  $ nano analyze.sh

You see that this script loads settings by sourcing *globals.sh*, runs each subject's individual analysis, then has a space for us to run scripts to do our group analysis. After the comment marking where to run group analyses, add this line::

  bash scripts/group-localizer.sh

Save and exit. That's it! To test this out, first delete any pre-existing subject and group analyses::

  $ rm -rf subjects/*/analysis/firstlevel/*
  $ rm -rf subjects/*/analysis/secondlevel/*
  $ rm -rf group/analysis/firstlevel/*

Now run the whole analysis::

  $ bash analyze.sh

**Summary**::

  $ nano analyze.sh
  $ rm -rf subjects/*/analysis/firstlevel/*
  $ rm -rf subjects/*/analysis/secondlevel/*
  $ rm -rf group/analysis/firstlevel/*
  $ bash analyze.sh

