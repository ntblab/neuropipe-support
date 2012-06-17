==================
NeuroPipe Tutorial
==================



:author: Mason Simon
:edited by: Alexa Tompary
:email: ntblab@princeton.edu



.. contents::



----------------------------------------------
Chapter 2 - HRF analysis of block design study
----------------------------------------------

Now that you know how neuropipe works and why it's useful, let's use it to analyze some data.  In this study, you will be running an HRF analysis of a block design study that two subjects particpated in. First, you will analyze the first subject's data, and then template the analysis workflow to use on the second subject's data. Then, you will run a second-level analysis that combines the data from both subjects, and create a template to automate the second-level analysis for future subjects.  

Before you begin, make sure that you have a copy of your project folder that you made in the intro tutorial (ppa-hunt). 

Analyzing a subject
===================

We'll start by analyzing a single subject. To prepare for that, you'll need to know the order of the scans that were collected for subjects that took thsi experiment. A *run-order.txt* file is already made for you. Download that file and take a look::

  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_secondlevel/run-order.txt > prototype/copy/run-order.txt
  $ less prototype/copy/run-order.txt
  
Note that ERROR_RUN is listed for each scan that is irrelevant to this tutorial.

**Summary**::

  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_secondlevel/run-order.txt > prototype/copy/run-order.txt
  $ less prototype/copy/run-order.txt

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

This *README.txt* says your first step is to get some DICOM data and put it in a Gzipped TAR archive at *data/raw.tar.gz*. Like I mentioned, the data has already been collected. It's even TAR-ed and Gzipped. Hit "q" to quit *README.txt* and get the data with this command (NOTE: you must qrsh to a node on rondo for this to work)::

  $ cp /jukebox/ntb/packages/neuropipe/example_data/0608101_conatt02.raw.tar.gz data/raw.tar.gz

If you are not a part of the Princeton University network, or if you are not permitted to copy this file, email ntblab@princeton.edu to request access to this data. NOTE: *cp* just copies files, and here we've directed it to copy data that was prepared for this tutorial; it doesn't work in general to retrieve data after you've done a scan. On rondo at Princeton, you can use *~/prototype/link/scripts/retrieve-data-from-sun.sh* (which appears at *~/subjects/SUBJ/scripts/retrieve-data-from-sun.sh*) to get your data, as long as your subject's folder name matches the subject ID used during for your scan session.

**Summary**::

  $ ./scaffold 0608101_conatt02
  $ cd subjects/0608101_conatt02
  $ less README.txt
  $ cp /jukebox/ntb/packages/neuropipe/example_data/0608101_conatt02.raw.tar.gz data/raw.tar.gz


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

*prep.sh* calls four other scripts: one to do those transformations on the data, one to run the quality assurance tools, one to perform some more transformations on the data, and one called *render-fsf-templates.sh*. Don't worry about that last one for now--we'll cover it later. If you'd like, open those first three scripts to see what they do. Otherwise, press on::


  $ ./analyze.sh

Once *analyze.sh* completes (and it may take awhile, since it's working on so many tasks), look around *data/nifti*::

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

Click "Select 4D data" and select the file *data/nifti/0608101_conatt02_localizer01.nii.gz*; FEAT will analyze this data. Set "Output directory" to *analysis/firstlevel/localizer_hrf* (to capture the correct file path, browse to *analysis/firstlevel/*, and then manually type *localizer_hrf* to the end of the file path). FEAT will put the results of its analysis in this folder, but with ".feat" appended, or "+.feat" appended if this is the second analysis with this name that you've run. FEAT should have detected "Total volumes" as 244, but it may have mis-detected "TR (s)" as 3.0; if so, change that to 1.5, because this experiment had a TR length of 1.5 seconds. Because *protocol.txt* indicated there were 6 seconds of disdaqs (volumes of data at the start of the run that are discarded because the scanner needs a few seconds to settle down), and TR length is 1.5s, set "Delete volumes" to 4. Set "High pass filter cutoff (s)" to 128 to remove slow drifts from your signal.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-data.png

Go to the Pre-stats tab.


The Pre-stats tab
'''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Change "Slice timing correction" to "Interleaved (0,2,4 ...", because slices were collected in this interleaved pattern. Leave the rest of the settings at their defaults.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-pre-stats.png

Go to the Stats tab.


The Stats tab
'''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Check "Add motion parameters to model"; this makes regressors from estimates of the subject's motion, which hopefully absorb variance in the signal due to transient motion. To account for the variance in the signal due to the experimental manipulation, we define regressors based on the design, as described in *protocol.txt*. *protocol.txt* says that blocks consisted of 12 trials, each 1.5s long, with 12s rest between blocks, and 6s rest at the start to let the scanner settle down. That 6s at the start was taken care of in the Data tab, so we have a design that looks like Scene, rest, Face, rest, Scene, rest, ...

We will specify this design using text files in FEAT's 3-column format: we make 1 text file per regressor, each with one line per period of time belonging to that regressor. Each line has 3 numbers, separated by whitespace. The first number indicates the onset time in seconds of the period. The second number indicates the duration of the period. The third number indicates the height of the regressor during the period; always set this to 1 unless you know what you're doing. See `FEAT's documentation`_ for more details.

.. _FEAT's documentation: http://www.fmrib.ox.ac.uk/fsl/feat5/detail.html#stats

These design files are provided for you. Download the files and put them in the *design* folder, where any design-related information about your analyses can be kept::

  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_secondlevel/scene.txt > design/scene.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_secondlevel/face.txt > design/face.txt

Examine each of these files and refer to *protocol.txt* as necessary::

  $ less design/scene.txt
  $ less design/face.txt

When making these design files for your own projects, do not use a Windows machine or you will likely have `problems with line endings`_.

.. _`problems with line endings`: http://en.wikipedia.org/wiki/Newline#Common_problems

To use these files to specify the design, click the "Full model setup" button. Set EV name to "scene". FSL calls regressors EV's, short for Explanatory Variables. Set "Basic shape" to "Custom (3 column format)" and select *design/scene.txt*. That file on its own describes a square wave; to account for the shape of the BOLD response, we convolve it with another function that models the hemodynamic response to a stimulus. Set "Convolution" to "Double-Gamma HRF". Now to set up the face regressor, set "Number of original EVs" to 2 and click to tab 2.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-stats-ev1.png

Set EV name to "face". Set "Basic shape" to "Custom (3 column format)" and select *design/face.txt*. Change "Convolution" to "Double-Gamma HRF", like we did for the scene regressor.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-stats-ev2.png

Now go to the "Contrasts & F-tests" tab. Increase "Contrasts" to 4. There is now a matrix of number fields with a row for each contrast and a column for each EV. You specify a contrast as a linear combination of the parameter estimates on each regressor. We'll make one contrast to show the main effect of the face regressor, one to show the main effect of the scene regressor, one to show where the scene regressor is greater than the face regressor, and one to show where the face regressor is greater:

* Set the 1st row's title to "scene", its "EV1" value to 1, and its "EV2" value to 0.
* Set the 2nd row's title to "face", its "EV1" value to 0, and its "EV2" value to 1.
* Set the 3rd row's title to "scene>face", its "EV1" value to 1, and its "EV2" value to -1.
* Set the 4th row's title to "face>scene", its "EV1" value to -1, and its "EV2" value to 1.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-stats-contrasts-and-f-tests.png

Click 'Done', and FEAT shows you a graph of your model. If it's different from the one below, check you followed the instructions correctly.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-model-graph.png

Go to the Registration tab.

**Summary**::

  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_secondlevel/scene.txt > design/scene.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_secondlevel/face.txt > design/face.txt
  $ less design/scene.txt
  $ less design/face.txt


The Post-stats tab
''''''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02
   
This step is optional, but strongly recommended if you are working on Princeton's server (rondo). In order to save space on the server and avoid creating unnecessary files, uncheck 'create time series plots.'

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-poststats.png
   

The Registration tab
''''''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Different subjects have different shaped brains, and may have been in different positions in the scanner. To compare the data collected from different subjects, for each subject we compute the transformation that best moves and warps their data to match a standard brain, apply those transformations, then compare each subject in this "standard space". This Registration tab is where we set the parameters used to compute the transformation; we won't actually apply the transformation until we get to group analysis.

The subject's functional data is first registered to the initial structural image, then that is registered to the main structural image, which is then registered to the standard space image. All this indirection is necessary because registration can fail, and it's more likely to fail if you try to go directly from the functional data to standard space.

FEAT should already have a "Standard space" image selected; leave it with the default, but change the drop-down menu from "Normal search" to "No search", or this subject's brain will be misregistered. Check "Initial structural image", and select the file *data/nifti/0608101_conatt02_t1_flash01.nii.gz*. Change the DOF from '3 (translation only)' to '6'. Check "Main structural image", and select the file *data/nifti/0608101_conatt02_t1_mprage_sag01.nii.gz*.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/feat-registration.png

That's it! Hit Go. A webpage should open in your browser showing FEAT's progress. Once it's done, this webpage provides a useful summary of the analysis you just ran with FEAT. When it's finished, we can continue hunting the PPA.


Finding the PPA
---------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Launch FSLView::

  $ fslview

Click File>Open... and select *analysis/firstlevel/localizer_hrf.feat/mean_func.nii.gz*; this is an image of the mean signal intensity at each voxel over the course of the run. We use it as a background to overlay a contrast image on. Click File>Add... *analysis/firstlevel/localizer_hrf.feat/stats/zstat3.nii.gz*. *zstat3.nii.gz* is an image of z-statistics for the scene>face contrast being different from 0, so high intensity values in a voxel indicate that the scene regressor caught much more of the variance in fMRI signal at that voxel than the face regressor. To find the PPA, we'll look for regions with really high values in *zstat3.nii.gz*. To include only these regions in the overlay, set the Min threshold at the top of FSLView to something like 6 or 7, then click around in the brain to see what regions had contrast z-stats at that threshold or above. Look for a bilateral pair of regions with zstat's at a high threshold, around the middle of the brain; that'll be the PPA.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/fslview-ppa.png


Repeating the analysis for a new subject
========================================

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Congratulations on analyzing your first subject with NeuroPipe! Now, we'll do it again, but with less work. FEAT recorded all parameters of the analysis you just ran, in a file called *design.fsf* in its output directory, which was *analysis/firstlevel/localizer_hrf.feat/*. Our approach is to take that file, replace subject-specific settings with placeholders, then for each new subject, automatically substitute appropriate values for the placeholders, and run FEAT with the resulting file.


Templating the fsf file
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608101_conatt02

Start by copying the *design.fsf* file for the analysis we just ran to *fsf*, and give it a ".template" extension::

  $ cp analysis/firstlevel/localizer_hrf.feat/design.fsf fsf/localizer_hrf.fsf.template

We'll keep fsf files and their templates in this *fsf* folder. Now, open *fsf/localizer_hrf.fsf.template* in your favorite text editor. If you don't have a favorite, try this::

  $ nano fsf/localizer_hrf.fsf.template

Make the following replacements and save the file. Be sure to include the spaces after "<?=" and before "?>".

::
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", replace all of the text inside the quotes with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set feat_files(1)", replace all of the text inside the quotes with "<?= $DATA_FILE_PREFIX ?>"
  #. on the line starting with "set initial_highres_files(1) ", replace all of the text inside the quotes with "<?= $INITIAL_HIGHRES_FILE ?>"
  #. on the line starting with "set highres_files(1)", replace all of the text inside the quotes with "<?= $HIGHRES_FILE ?>"

Those bits you replaced with placeholders are the parameters that must change when analyzing a different subject, or using a different computer. After saving the file, copy it to the prototype so it's available for future subjects::

  $ cp fsf/localizer_hrf.fsf.template ../../prototype/copy/fsf/

Recall that the *prototype/copy* holds files that should initially be the same, but may need to vary between subjects. We put the fsf file there because it may need to be tweaked for future subjects - to fix registration problems, for instance.

**Summary**::

  $ cp analysis/firstlevel/localizer_hrf.feat/design.fsf fsf/localizer_hrf.fsf.template
  $ nano fsf/localizer_hrf.fsf.template
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

  $ nano scripts/localizer.sh

Then fill it with this text::

  #!/bin/bash
  source globals.sh
  feat $FSF_DIR/localizer_hrf.fsf

The first line says that this is a BASH script. The second line loads variables from *globals.sh*. The third line calls *feat*, which runs FEAT without the graphical interface. The argument passed to *feat* is the path to the fsf file for it to use. Notice that the path is specified with a variable "$FSF_DIR", which is defined in *globals.sh*.

To make this script available in future subject directories, copy it to the prototype::

  $ cp scripts/localizer.sh ../../prototype/link/scripts/

Remember, *prototype/link* holds files that should be identical in each subject's directory. Any file in that directory will be linked into each new subject's directory: when a linked file is changed in one subject's directory (or in *prototype/link*), the change is immediately reflected in all other links to that file.

Now that we have a script for running the GLM analysis, we'll call it from *analyze.sh* so that one command does the entire analysis. Open *analyze.sh* in your text editor::

  $ nano analyze.sh

After the line that runs *prep.sh*, add these lines::
  
  bash scripts/localizer.sh
  bash scripts/wait-for-feat.sh analysis/firstlevel/localizer_hrf.feat

That second line calls a script that waits for Feat to finish before moving on to the next task. It's helpful later on. *analyze.sh* is linked to *~/prototype/link/analyze.sh*, so the change you just made will be reflected in *analyze.sh* in all current and future subject directories. Test that worked by analyzing a new subject. First, move back to the project's root directory::

  $ cd ../../

Scaffold a directory for the new subject::

  $ ./scaffold 0608102_conatt02

Move into that subject's directory::

  $ cd subjects/0608102_conatt02

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608102_conatt02

Get the subject's data (NOTE: you must be on a node, on rondo for this to work)::

  $ cp /jukebox/ntb/packages/neuropipe/example_data/0608102_conatt02.raw.tar.gz data/raw.tar.gz

As before, if you don't have access to this file; email ntblab@princeton.edu to request access.

Now, analyze it::

  $ ./analyze.sh

FEAT should be churning away on the new data.

**Summary**::
 
  $ nano scripts/localizer.sh
  $ cp scripts/localizer.sh ../../prototype/link/scripts/
  $ nano analyze.sh
  $ cd ../../
  $ ./scaffold 0608102_conatt02
  $ cd subjects/0608102_conatt02
  $ cp /jukebox/ntb/packages/neuropipe/example_data/0608102_conatt02.raw.tar.gz data/raw.tar.gz
  $ ./analyze.sh


Combining within-subjects analyses into a group analysis
========================================================

.. admonition:: you are here

   ~/ppa-hunt/subjects/0608102_conatt02

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

Change the drop-down in the top left from "First-level analysis" to "Higher-level analysis". This will change the layout of the rest of the tab. Set "Number of inputs" to 2, because we're combining 2 within-subjects analyses, then click "Select FEAT directories". For the first directory, select *~/ppa-hunt/subjects/0608101_conatt02/analysis/firstlevel/localizer_hrf.feat*, and for the second, select *~/ppa-hunt/subjects/0608102_conatt02/analysis/firstlevel/localizer_hrf.feat*. Set the output directory to *~/ppa-hunt/group/analysis/localizer_hrf*.

Go to the Stats tab.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/group-feat-data.png


The Stats tab
'''''''''''''

Click "Model setup wizard", leave it on the default option of "single group average", and click "Process". Make sure the top drop-down menu it set to 'Mixed Effects: FLAME 1.'

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_secondlevel/group-feat-stats.png


The Post-stats tab
'''''''''''''

Again, turn off the 'create time series plots' function to avoid making many unnecessary files, unless you specifically want them. And that's it! Hit "Go" to run the analysis.


Finding the group's PPA
-----------------------

.. admonition:: you are here

   ~/ppa-hunt/group

When the analysis finishes, open FSLview::

  $ fslview &

Click File>Open Standard and accept the default. Click File>Add, and select *~/ppa-hunt/group/analysis/localizer_hrf.gfeat/cope3.feat/stats/zstat1.nii.gz*. Set the minimum threshold to 2.3, and you should see the PPA in the same bilaterial posterior area as before.


Automating the group analysis
=============================

To automate the group analysis to work without additional effort when new subjects are added, we follow the same sort of procedure we did for within-subjects analyses: take the fsf file created when we manually ran FEAT, turn it into a template, write a script to render that template appropriately, then write a script to run FEAT on the rendered fsf file.


Templating the group fsf file
-----------------------------

.. admonition:: you are here

   ~/ppa-hunt/

When we made a template fsf file for the within-subject analyses, we didn't have to change the structure of the template, only replace single lines with placeholders. But to template a higher-level fsf file, we'll need to repeat whole sections of the fsf file for each subject going into the group analysis. To accomplish this, we'll use PHP_ to render the templates, and write loops_ for those sections of the template that need repeating for each subject. You won't need to know PHP to follow the steps below, but if you're curious about what we're doing, read that page on loops.

.. _PHP: http://en.wikipedia.org/wiki/PHP
.. _loops: http://www.php.net/manual/en/control-structures.for.php

Start by copying the *design.fsf* file for the group analysis we just ran to *~/fsf*, and give it a ".template" extension::

  $ cp group/analysis/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf.fsf.template

Now, open *fsf/localizer_hrf.fsf.template* in your favorite text editor::

  $ nano fsf/localizer_hrf.fsf.template

Make the following replacements and save the file. Be sure to include the spaces after each "<?=" and before each "?>".

::
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", copy or write down the text inside the quotes, then replace it with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set fmri(npts)", replace the number at the end of the line with "<?= count($subjects) ?>"
  #. on the line starting with "set fmri(multiple)", replace the number at the end of the line with "<?= count($subjects) ?>"

Those were the parts of the template that won't vary with the number of subjects; now we template the parts that will, using loops. 

Find the line that says "# 4D AVW data or FEAT directory (1)". Replace it and the next 4 lines with::

  <?php for ($i=0; $i < count($subjects); $i++) { ?>
  # 4D AVW data or FEAT directory (<?= $i+1 ?>)
  set feat_files(<?= $i+1 ?>) "<?= $SUBJECTS_DIR ?>/<?= $subjects[$i] ?>/analysis/firstlevel/localizer_hrf.feat"

  <?php } ?>

Again, the inserted PHP code should completely replace the two original blocks of code that dictate 'group membership' for each subject. Since we are averaging across the subjects' data, they will all belong to the same 'group'. Next, find the line that says "# Higher-level EV value for EV 1 and input 1". Replace it and the next 4 lines with::

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

  $ cp group/analysis/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf.fsf.template
  $ nano fsf/localizer_hrf.fsf.template


Automating the group analysis
-----------------------------

.. admonition:: you are here

   ~/ppa-hunt/group

Now that we have a template for the group localizer analysis fsf file, all that's left is to render it and run FEAT on the rendered fsf file. Move up to the project directory and make a file called *localizer.sh* in the *scripts* folder with your text editor::

  $ cd ..
  $ nano scripts/localizer.sh

.. admonition:: you are here

   ~/ppa-hunt

Copy these lines into localizer.sh::

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
    \$SUBJECTS_DIR = '$PROJECT_DIR/$SUBJECTS_DIR';
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
  fsf_template=$PROJECT_DIR/fsf/localizer_hrf.fsf.template
  fsf_file=$PROJECT_DIR/fsf/localizer_hrf.fsf
  output_dir=$PROJECT_DIR/$GROUP_DIR/analysis/localizer_hrf.gfeat
  define_vars $output_dir | cat - "$fsf_template" | php > "$fsf_file"
  feat "$fsf_file"

If the text following "STANDARD_BRAIN=" differs from what you copied out of the fsf file in the previous section, replace it with that text you copied.

Save and close the script, then run it to test that everything works::

  $ bash scripts/localizer.sh

A webpage should open in your browser showing FEAT's progress. Because we manually ran this analysis and put its output into *~/ppa-hunt/group/analysis/localizer_hrf.gfeat*, FEAT should have created a new directory at *~/ppa-hunt/group/analysis/localizer_hrf+.gfeat*, and be showing you the analysis running in that directory.

**Summary**::

  $ cd ..
  $ nano scripts/localizer.sh
  $ bash scripts/localizer.sh


Automating the entire analysis
==============================

.. admonition:: you are here

   ~/ppa-hunt

Our goal was to run the entire analysis with a single command, to make it easy to reproduce. We're close. Open *analyze-group.sh* in your text editor::

  $ nano analyze-group.sh

You see that this script loads settings by sourcing *globals.sh*, runs each subject's individual analysis, then has a space for us to run scripts to do our group analysis. 

After the comment marking where to run group analyses, add this line::

  bash scripts/localizer.sh

Save and exit. That's it! To test this out, first delete any pre-existing subject and group analyses::

  $ rm -rf subjects/*/analysis/firstlevel/*
  $ rm -rf group/analysis/*

Now run the whole analysis::

  $ ./analyze-group.sh

**Summary**::

  $ nano analyze.sh
  $ rm -rf subjects/*/analysis/firstlevel/*
  $ rm -rf group/analysis/*
  $ ./analyze-group.sh

