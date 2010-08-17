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

This tutorial walks you through using NeuroPipe for a within-subjects analysis on one subject, repeating that analysis for a second subject, and then running a group analysis across both of these subjects. For our example analysis, we fit a GLM to data collected while subjects viewed blocks of scene images and face images, in order to locate the PPA in these subjects.


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

To access the data that you'll analyze in this tutorial, email ntblab@gmail.com and request the password.


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

NeuroPipe provides the flexibility to analyze non-standard subjects, while minimizing duplication, by making you specify which parts of your pipeline may vary between subjects and which wont. You make whatever scripts and files are necessary to analyze an ideal subject and then use those as a basis for each new subject's pipeline. This is called the prototype and it's stored in the *prototype* directory of your project. The files that may vary between subjects go into *prototype/copy*, and they will be copied into each new subject's directory. The ones that won't vary go into *prototype/link*, and they will be symlinked into each new subject's directory; that means that changing a linked file in any subject's directory will immediately change that file in all subject's directories. If you have a non-standard subject, you change the (copied) files within that subject's directory, and other subjects are unaffected. If you must change the analysis for every subject, you change the linked files in the prototype, and the change is reflected in each subject's (linked) analysis scripts.

This architecture is diagrammed in the PDF here_.

.. _here: http://docs.google.com/viewer?url=http%3A%2F%2Fgithub.com%2Fntblab%2Fneuropipe-support%2Fraw%2Fmaster%2Fdoc%2Farchitecture.pdf


Setting up your NeuroPipe project
=================================

.. admonition:: you are here

   ~/

NeuroPipe is a sort of skeleton for fMRI analysis projects using FSL. To work with it, you download that skeleton, then flesh it out.

We'll use git to grab the latest copy of NeuroPipe. But before that, configure git with your current name, email, and text editor of choice (if you haven't already)::

  $ git config --global user.name "YOUR NAME HERE"
  $ git config --global user.email "YOUR_EMAIL@HERE.COM"
  $ git config --global core.editor nano

Now, using git, download NeuroPipe into a folder called *ppa-hunt*::

  $ git clone git://github.com/ntblab/neuropipe.git ppa-hunt

Move into that directory and look around::

  $ cd ppa-hunt
  $ ls

.. admonition:: you are here

   ~/ppa-hunt

You should see a *README.txt* file, a command called *scaffold*, a file called *protocol.txt*, and a directory called *prototype*. Start by reading *README.txt*::

  $ less README.txt

The first instruction in the Getting Started section is to open *protocol.txt* and follow its instructions. Hit "q" to quit *README.txt*, then open *protocol.txt*::

  $ less protocol.txt

It says to fill it in with details on the data collection protocol. We'll just download a *protocol.txt* file that describes the ppa-hunt data you're about to analyze. Hit "q" to quit out of *protocol.txt*, then run these commands::

  $ rm protocol.txt
  $ wget http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/protocol.txt

Read that newly downloaded *protocol.txt*::

  $ less protocol.txt

Hit "q", and open *README.txt* again::

  $ less README.txt

The next instruction is to open *prototype/copy/run-order.txt*. Hit "q", then read that file::

  $ less prototype/copy/run-order.txt

As with *protocol.txt*, a *run-order.txt* file is already made for you. Download that file, and put it where *README.txt* says::

  $ curl http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/run-order.txt > prototype/copy/run-order.txt

Open *README.txt* one last time::

  $ less README.txt

It says the next step is to collect data for a subject. That's already been done, so skip that step. The final instruction is to run the command *./scaffold SUBJECT_ID*, with a real subject ID inserted in place of "SUBJECT_ID".

**Summary**::

  $ neuropipe/np ppa-hunt
  $ cd ppa-hunt
  $ ls
  $ less README.txt
  $ less protocol.txt
  $ rm protocol.txt
  $ wget http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/protocol.txt
  $ less protocol.txt
  $ less README.txt
  $ less prototype/copy/run-order.txt
  $ curl http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/run-order.txt > prototype/copy/run-order.txt
  $ less README.txt


Analyzing a subject
===================

We'll start by analyzing a single subject.


Setting up
----------

.. admonition:: you are here

   ~/ppa-hunt

Our subject ID is "0608101_conatt02", so run this command::

  $ ./scaffold 0608101_conatt02

*scaffold* tells you that it made a subject directory at *subjects/0608101_conatt02* and that you should read the README.txt file there if this is your first time setting up a subject. Move into the subject's directory, and do what it says::

  $ cd subjects/0608101_conatt02
  $ less README.txt

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

This *README.txt* says your first step is to get some DICOM data and put it in a Gzipped TAR archive at *data/raw.tar.gz*. Like I mentioned, the data has already been collected. It's even TAR-ed and Gzipped. Hit "q" to quit *README.txt* and get the data with this command::

  $ curl -u ntblab http://www.princeton.edu/ntblab/resources/0608101_conatt02.tar.gz > data/raw.tar.gz

It will prompt you to enter a password; email ntblab@gmail.com to request access to this data if you don't have it.

**Summary**::

  $ ./scaffold 0608101_conatt02
  $ cd subjects/0608101_conatt02
  $ less README.txt
  $ curl -u ntblab http://www.princeton.edu/ntblab/resources/0608101_conatt02.tar.gz > data/raw.tar.gz


Preparing your data for analysis
--------------------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

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

*prep.sh* calls three other scripts: one to do those transformations on the data, one to run the quality assurance tools, and one called *render-fsf-templates.sh*. Don't worry about that last one for now--we'll cover it later. If you'd like, open those first two scripts to see what they do. Otherwise, press on::

  $ ./analyze.sh

Once *analyze.sh* completes, look around *data/nifti*::

  $ ls data/nifti

There should be a pair of .bxh/.nii.gz files for each pulse sequence listed in *run-order.txt*, excluding the sequences called ERROR_RUN. Open the .nii.gz files with FSLView_, if you'd like, using a command like this::

  $ fslview data/nifti/0608101_conatt02_t1_mprage_sag01.nii.gz

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
  $ fslview data/nifti/0608101_conatt02_t1_mprage_sag01.nii.gz
  $ firefox data/qa/index.html


GLM analysis with FEAT (first-level)
------------------------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

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

   ~/ppa-hunt/subjects/0608101_conatt02

Click "Select 4D data" and select the file *data/nifti/localizer01.nii.gz*; FEAT will analyze this data. Set "Output directory" to *analysis/firstlevel/localizer_hrf*; FEAT will put the results of its analysis in this folder, but with ".feat" appended, or "+.feat" appended if this is the second analysis with this name that you've run. FEAT should have detected "Total volumes" as 244, but it may have mis-detected "TR (s)" as 3.0; if so, change that to 1.5, because this experiment had a TR length of 1.5 seconds. Because *protocol.txt* indicated there were 6 seconds of disdaqs (volumes of data at the start of the run that are discarded because the scanner needs a few seconds to settle down), and TR length is 1.5s, set "Delete volumes" to 4. Set "High pass filter cutoff (s)" to 128 to remove slow drifts from your signal.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/feat-data.png

Go to the Pre-stats tab.


The Pre-stats tab
'''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Change "Slice timing correction" to "Interleaved (0,2,4 ...", because slices were collected in this interleaved pattern. Leave the rest of the settings at their defaults.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/feat-pre-stats.png

Go to the Stats tab.


The Stats tab
'''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Check "Add motion parameters to model"; this makes regressors from estimates of the subject's motion, which hopefully absorb variance in the signal due to transient motion. To account for the variance in the signal due to the experimental manipulation, we define regressors based on the design, as described in *protocol.txt*. *protocol.txt* says that blocks consisted of 12 trials, each 1.5s long, with 12s rest between blocks, and 6s rest at the start to let the scanner settle down. That 6s at the start was taken care of in the Data tab, so we have a design that looks like Scene, rest, Face, rest, Scene, rest, ...

We will specify this design using text files in FEAT's 3-column format: we make 1 text file per regressor, each with one line per period of time belonging to that regressor. Each line has 3 numbers, separated by whitespace. The first number indicates the onset time in seconds of the period. The second number indicates the duration of the period. The third number indicates the height of the regressor during the period; always set this to 1 unless you know what you're doing. See `FEAT's documentation`_ for more details.

.. _FEAT's documentation: http://www.fmrib.ox.ac.uk/fsl/feat5/detail.html#stats

These design files are provided for you. Make a directory to put them in, then download the files::

  $ mkdir design
  $ curl http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/scene.txt >design/scene.txt
  $ curl http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/face.txt >design/face.txt

Examine each of these files and refer to *protocol.txt* as necessary::

  $ less design/scene.txt
  $ less design/face.txt

When making these design files for your own projects, do not use a Windows machine or you will likely have `problems with line endings`_.

.. _`problems with line endings`: http://en.wikipedia.org/wiki/Newline#Common_problems

To use these files to specify the design, click the "Full model setup" button. Set EV name to "scene". FSL calls regressors EV's, short for Explanatory Variables. Set "Basic shape" to "Custom (3 column format)" and select *design/scene.txt*. That file on its own describes a square wave; to account for the shape of the BOLD response, we convolve it with another function that models the hemodynamic response to a stimulus. Set "Convolution" to "Double-Gamma HRF". Now to set up the face regressor set "Number of original EVs" to 2 and click to tab 2.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/feat-stats-ev1.png

Set EV name to "face". Set "Basic shape" to "Custom (3 column format)" and select *design/face.txt*. Change "Convolution" to "Double-Gamma HRF", like we did for the scene regressor.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/feat-stats-ev2.png

Now go to the "Contrasts & F-tests" tab. Increase "Contrasts" to 4. There is now a matrix of number fields with a row for each contrast and a column for each EV. You specify a contrast as a linear combination of the parameter estimates on each regressor. We'll make one contrast to show the main effect of the face regressor, one to show the main effect of the scene regressor, one to show where the scene regressor is greater than the face regressor, and one to show where the face regressor is greater:

* Set the 1st row's title to "scene", it's "EV1" value to 1, and it's "EV2" value to 0.
* Set the 2nd row's title to "face", it's "EV1" value to 0, and it's "EV2" value to 1.
* Set the 3rd row's title to "scene>face", it's "EV1" value to 1, and it's "EV2" value to -1.
* Set the 4th row's title to "face>scene", it's "EV1" value to -1, and it's "EV2" value to 1.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/feat-stats-contrasts-and-f-tests.png

Close that window, and FEAT shows you a graph of your model. If it's different from the one below, check you followed the instructions correctly.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/feat-model-graph.png

Go to the Registration tab.

**Summary**::

  $ mkdir design
  $ curl http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/scene.txt >design/scene.txt
  $ curl http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/face.txt >design/face.txt
  $ less design/scene.txt
  $ less design/face.txt


The Registration tab
''''''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Different subjects have different shaped brains, and may have been in different positions in the scanner. To compare the data collected from different subjects, for each subject we compute the transformation that best moves and warps their data to match a standard brain, apply those transformations, then compare each subject in this "standard space". This Registration tab is where we set the parameters used to compute the transformation; we won't actually apply the transformation until we get to group analysis.

FEAT should already have a "Standard space" image selected; leave it with the default, but change the drop-down menu from "Normal search" to "No search", or this subject's brain will be misregistered. Check "Initial structural image", and select the file *subjects/0608101_conatt02/data/nifti/0608101_conatt02_t1_flash01.nii.gz*. Check "Main structural image", and select the file *subjects/0608101_conatt02/data/nifti/0608101_conatt02_t1_mprage_sag01.nii.gz*.

The subject's functional data is first registered to the initial structural image, then that is registered to the main structural image, which is then registered to the standard space image. All this indirection is necessary because registration can fail, and it's more likely to fail if you try to go directly from the functional data to standard space.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/feat-registration.png

That's it! Hit Go. A webpage should open in your browser showing FEAT's progress. Once it's done, this webpage provides a useful summary of the analysis you just ran with FEAT. Later, we'll make a webpage for this subject to gather information like this FEAT report, the QA results, and plots summarizing this subject's data. But for now, let's continue hunting the PPA.


Finding the PPA
---------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Launch FSLView::

  $ fslview

Click File>Open... and select *analysis/firstlevel/localizer_hrf.feat/mean_func.nii.gz*; this is an image of the mean signal intensity at each voxel over the course of the run. We use it as a background to overlay a contrast image on. Click File>Add... *analysis/firstlevel/localizer_hrf.feat/stats/zstat3.nii.gz*. *zstat3.nii.gz* is an image of z-statistics for the scene>face contrast being different from 0, so high intensity values in a voxel indicate that the scene regressor caught much more of the variance in fMRI signal at that voxel than the face regressor. To find the PPA, we'll look for regions with really high values in *zstat3.nii.gz*. To include only these regions in the overlay, set the Min threshold at the top of FSLView to something like 8, then click around in the brain to see what regions had contrast z-stats at that threshold or above. Look for a bilateral pair of regions with zstat's at a high threshold, around the middle of the brain; that'll be the PPA.


Repeating the analysis for a new subject
========================================

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Congratulations on analyzing your first subject with NeuroPipe! Now, we'll do it again, but more automatically. FEAT recorded all parameters of the analysis you just ran, in a file called *design.fsf* in its output directory, which was *analysis/firstlevel/localizer_hrf.feat/*. Our approach is to take that file, replace subject-specific settings with placeholders, then for each new subject, automatically substitute appropriate values for the placeholders, and run FEAT with the resulting file.


Templating the fsf file
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Start by copying the *design.fsf* file for the analysis we just ran to a more central location::

  $ mv analysis/firstlevel/localizer_hrf.feat/design.fsf fsf/localizer_hrf.fsf

We'll keep fsf files and their templates in this *fsf* folder. Now, open *fsf/localizer_hrf.fsf* in your favorite text editor. If you don't have a favorite, try this::

  $ nano fsf/localizer_hrf.fsf

Make the following replacements and save the file as *fsf/localizer_hrf.fsf.template*. Be sure to include the spaces after "<?=" and before "?>".

::
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", replace all of the text inside the quotes with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set feat_files(1)", replace all of the text inside the quotes with "<?= $DATA_FILE_PREFIX ?>"
  #. on the line starting with "set initial_highres_files(1) ", replace all of the text inside the quotes with "<?= $INITIAL_HIGHRES_FILE ?>"
  #. on the line starting with "set highres_files(1)", replace all of the text inside the quotes with "<?= $HIGHRES_FILE ?>"

Those bits you replaced with placeholders are the parameters that must change when analyzing a different subject, or using a different computer. After saving the file as *fsf/localizer_hrf.fsf.template*, copy it to the prototype so it's available for future subjects::

  $ cp fsf/localizer_hrf.fsf.prototype ../../prototype/copy/fsf/

Recall that the *prototype/copy* holds files that should initially be the same, but may need to vary between subjects. We put the fsf file there because it may need to be tweaked for future subjects - to fix registration problems, for instance.

**Summary**::

  $ mv analysis/firstlevel/localizer_hrf.feat/design.fsf fsf/localizer_hrf.fsf
  $ nano fsf/localizer_hrf.fsf
  $ cp fsf/localizer_hrf.fsf.template ../../prototype/copy/fsf/


Rendering the template
----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Now, we have a template fsf file. To use that template, we need a script that fills it in, appropriately, for each subject. This filling-in process is called rendering, and a script that does most of the work is provided at *scripts/render-fsf-templates.sh*. Open that in your text editor::

  $ nano scripts/render-fsf-templates.sh

It consists of a function called render_firstlevel, which we'll use to render the localizer template. Copy these lines as-is onto the end of that file, then save it::

  render_firstlevel $FSF_DIR/localizer_hrf.fsf.template \
                    $FIRSTLEVEL_DIR/localizer_hrf.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_localizer01 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage_sag01.nii.gz \
                    > $FSF_DIR/localizer_hrf.fsf

That hunk of code calls the function render_firstlevel, passing it the values to substitute for the template's placeholders. These values use a bunch of completely-uppercase variables, which are defined in *globals.sh*.  Examine *globals.sh*::

  $ less globals.sh

*scripts/convert-and-wrap-raw-data.sh* needs to know where to look for the subject's raw data, and where to put the converted and wrapped data. *scripts/qa-wrapped-data.sh* needs to know where that wrapped data was put. To avoid hardcoding that information into each script, those locations are defined as variables in *globals.sh*, which each script then loads. By building the call to render_firstlevel with those variables, we won't need to modify it for each subject, and if you ever change the structure of your subject directory, all you must do is modify *globals.sh* to reflect the changes.

**Summary**::

  $ nano scripts/render-fsf-templates.sh
  $ less globals.sh


Automating the analysis
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

As we saw earlier, *prep.sh* already calls *render-fsf-templates.sh*. *analyze.sh* calls *prep.sh*, so to automate the analysis, all that remains is running *feat* on the rendered fsf file from a script that's called by *analyze.sh*. We'll make a new script called *localizer.sh* for that purpose. Make the script with this command::

  $ nano localizer.sh

Then fill it with this text::

  #!/bin/bash
  source globals.sh
  feat $FSF_DIR/localizer_hrf.fsf

The first line says that this is a BASH script. The second line loads variables from *globals.sh*. The third line calls *feat*, which runs FEAT without the graphical interface. The argument passed to *feat* is the path to the fsf file for it to use. Notice that the path is specified with a variable "$FSF_DIR", which is defined in *globals.sh*.

To make this script available in future subject directories, copy it to the prototype::

  $ cp localizer.sh ../../prototype/link/

Remember, *prototype/link* holds files that should be identical in each subject's directory. Any file in that directory will be linked into each new subject's directory: when a linked file is changed in one subject's directory (or in *prototype/link*), the change is immediately reflected in all other links to that file.

Now that we have a script for running the GLM analysis, we'll call it from *analyze.sh* so that one command does the entire analysis. Open *analyze.sh* in your text editor::

  $ nano analyze.sh

After the line that runs *prep.sh*, add this line::
  
  bash localizer.sh

*analyze.sh* is linked to *~/prototype/link/analyze.sh*, so the change you just made will be reflected in *analyze.sh* in all current and future subject directories. Test that worked by analyzing a new subject. First, move back to the project's root directory::

  $ cd ../../

Scaffold a directory for the new subject::

  $ ./scaffold 0608102_conatt02.

Move into that subject's directory::

  $ cd subjects/0608102_conatt02

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Download the subject's data::

  $ curl -u ntblab http://www.princeton.edu/ntblab/resources/0608102_conatt02.tar.gz > data/raw.tar.gz

As before, it will prompt you to enter a password; email ntblab@princeton.edu to request access to this data.

Now, analyze it::

  $ ./analyze.sh

FEAT should be churning away on the new data.

**Summary**::
 
  $ nano localizer.sh
  $ cp localizer.sh ../../prototype/link/
  $ nano analyze.sh
  $ cd ../../
  $ ./scaffold 0608102_conatt02.
  $ cd subjects/0608102_conatt02
  $ curl -u ntblab http://www.princeton.edu/ntblab/resources/0608102_conatt02.tar.gz > data/raw.tar.gz
  $ ./analyze.sh


Combining within-subjects analyses into a group analysis
========================================================

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Now that we've found the PPAs for two subjects individually, it's time to perform a group analysis to learn how reliable the PPA location is across these subjects. We'll use FEAT again to run what it calls a "higher-level analysis", which takes the information from those "first-level" analyses that we just did. The process will be very similar to that in `GLM analysis with FEAT (first-level)`_.


GLM analysis with FEAT (higher-level)
-------------------------------------

Move up to the root project folder::

  $ cd ../../

.. admonition:: you are here

   ~/ppa-hunt

Launch FEAT::

  $ Feat &


The Data tab
''''''''''''

Change the drop-down in the top left from "First-level analysis" to "Higher-level analysis". This will change the stuff you see below. Change "Number of inputs" to 2, because we're combining 2 within-subjects analyses, then click "Select FEAT directories". For the first directory, select *~/ppa-hunt/subjects/0608101_conatt02/analysis/firstlevel/localizer_hrf.feat(, and for the second, select *~/ppa-hunt/subjects/0608102_conatt02/analysis/firstlevel/localizer_hrf.feat*. Set the output directory to *~/ppa-hunt/analysis/localizer_hrf*.

Go to the Stats tab.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/group-feat-data.png


The Stats tab
'''''''''''''

Click "Model setup wizard", leave it on the default option of "single group average", and click "Process". That's it! Hit "Go" to run the analysis.

.. image:: http://github.com/ntblab/neuropipe-support/raw/master/doc/tutorial/group-feat-stats.png


Finding the group's PPA
-----------------------

.. admonition:: you are here

   ~/ppa-hunt

When the analysis finishes, open FSLview::

  $ fslview &

Click File>Open Standard and accept the default. Click File>Add, and select *~/ppa-hunt/analysis/localizer_hrf.gfeat/cope3.feat/stats/zstat1.nii.gz*. 
