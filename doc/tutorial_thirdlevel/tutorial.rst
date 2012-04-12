==================
NeuroPipe Tutorial
==================



:author: Alexa Tompary
:email: ntblab@princeton.edu



.. contents::



---------------------------------------------------
Chapter 3 - HRF analysis of multiple scan sequneces
---------------------------------------------------

In this tutorial, you are interested in running an HRF analysis on two separate subjects' data. However, both subjects completed two separate scan sequences while performing the same task. Here you will begin by analyzing the first 'run' of one a subject, and then template the analysis to automate the analysis of the second 'run'. Then you will run a second-level analysis of the two runs to combine the results. Then, you will create a template of the second-level analysis in order to replicate this analysis on the second subject. Finally, you will run a third-level analysis that combines the results of both subjects.


Analyzing a subject
===================

We'll start by analyzing a single subject. Make sure you have created a project folder to work in (see the intro tutorial for help). The name of the project for this tutorial is 'ppa-hunt2'. We will start by setting up a folder to store this subject's brain data, as well as information about the design and analysis of the data. Then we convert the data to NIFTI and run some quality assurance tests. Finally, we will set up a GLM model in Feat for one of the functional runs that were collected.

Setting up
----------

.. admonition:: you are here

   ~/ppa-hunt2

Our subject ID is "0831101_confba02", so run this command::

 $ ./scaffold 0831101_confba02

*scaffold* tells you that it made a subject directory at *subjects/0831101_confba02* and that you should read the *README.txt* file there if this is your first time setting up a subject. Move into the subject's directory, and do what it says::

 $ cd subjects/0831101_confba02
 $ less README.txt

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

This *README.txt* says your first step is to get some DICOM data and put it in a Gzipped TAR archive at *data/raw.tar.gz*. Like I mentioned, the data has already been collected. It's even TAR-ed and Gzipped. Hit "q" to quit *README.txt* and get the data with this command (NOTE: you must be on on a node, on rondo for this to work)::

 $ cp /jukebox/ntb/packages/neuropipe/example_data/0831101_confba02.raw.tar.gz data/raw.tar.gz

Email ntblab@gmail.com to request access to this data if you can't use the above command. NOTE: *cp* just copies files, and here we've directed it to copy data that was prepared specifically for this tutorial; it doesn't work in general to retrieve data after you've done a scan. On rondo at Princeton, you can use *~/prototype/link/scripts/retrieve-data-from-sun.sh* (which appears at *~/subjects/SUBJECT/scripts/retrieve-data-from-sun.sh*) to get your data, as long as your subject's folder name matches the subject ID used during for your scan session.

We also need to know the order of the scans that were collected for this subject. Download this file to see it (remember, if you're working on rondo, you cannot use the curl command on a node; exit to the headnode to collect the file)::

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_run-order.txt > run-order.txt
 
ERROR_RUN is listed for any scans that are not relevant to this tutorial.

**Summary**::

 $ ./scaffold 0831101_confba02
 $ cd subjects/0831101_confba02
 $ less README.txt
 $ cp /jukebox/ntb/packages/neuropipe/example_data/0831101_confba02.raw.tar.gz data/raw.tar.gz
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_run-order.txt > run-order.txt


Preparing your data for analysis
--------------------------------

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Open *README.txt* again::

 $ less README.txt

It says that we should proceed by doing various transformations on the data, and then running a quality assurance tool to make sure the data is usable. The transformations make the data more palatable to FSL_, which we will use for analysis. As *README.txt* says, you do all that with the command *analyze.sh*. Before running that, see what it does::

 $ less analyze.sh

.. _FSL: http://www.fmrib.ox.ac.uk/fsl/

Look at the body of the script, and notice it just runs another script: *prep.sh*. Hit "q" to quit *analyze.sh* and read *prep.sh*::

 $ less prep.sh

*prep.sh* calls four other scripts: one to do those transformations on the data, one to run the quality assurance tools, one to perform some more transformations on the data, and one called *render-fsf-templates.sh*. Don't worry about that last one for now--we'll cover it later. If you'd like, open those first three scripts to see what they do. Otherwise, press on::

 $ ./analyze.sh

Once *analyze.sh* completes (and it will take some time to finish, so be patient)cd , look around *data/nifti*::

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

   ~/ppa-hunt2/subjects/0831101_confba02

Now that you have data, and of adequate quality, it's time to do an analysis. We'll use FSL's FEAT to perform a GLM-based analysis. If GLM analysis or FEAT is new to you, read `FEAT's manual`_ to learn more about them. If any of the steps seem mysterious to you, hover your mouse over the relevant part of FEAT and a tooltip will appear describing that part in detail.

.. _FEAT's manual: http://www.fmrib.ox.ac.uk/fsl/feat5/index.html

To set the parameters of the analysis, you must know the experimental design. Download that information and put it in the project directory::

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/protocol.txt > ../../protocol.txt

Take a look::

 $ less ../../protocol.txt

Now that we know the parameters of the experiment, launch FEAT::

 $ Feat &

It opens to the Data tab.

**Summary**::

 $ less ../../protocol.txt
 $ Feat &


The Data tab
''''''''''''

.. admonition:: you are here

~/ppa-hunt2/subjects/0831101_confba02

Click "Select 4D data" and select the file *data/nifti/0831101_confba02_localizer01.nii.gz*; FEAT will analyze this data. Set "Output directory" to *analysis/firstlevel/localizer_hrf_01*. To make sure you're using the right directory, use the browser to select *analysis/firstlevel* and then manually type in *localizer_hrf_01* at the end of the file path.  FEAT will put the results of its analysis in this folder, but with ".feat" appended, or "+.feat" appended if this is the second analysis with this name that you've run. FEAT should have detected "Total volumes" as 294, but it may have mis-detected "TR (s)" as 3.0; if so, change that to 1.5, because this experiment had a TR length of 1.5 seconds. Because *protocol.txt* indicated there were 6 seconds of disdaqs (volumes of data at the start of the run that are discarded because the scanner needs a few seconds to settle down), and TR length is 1.5s, set "Delete volumes" to 4. Set "High pass filter cutoff (s)" to 128 to remove slow drifts from your signal.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/feat-data.png

Go to the Pre-stats tab.


The Pre-stats tab
'''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Change "Slice timing correction" to "Interleaved (0,2,4 ...", because slices were collected in this interleaved pattern. Leave the rest of the settings at their defaults.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/feat-pre-stats.png

Go to the Stats tab.


The Stats tab
'''''''''''''

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Check "Add motion parameters to model"; this makes regressors from estimates of the subject's motion, which hopefully absorb variance in the signal due to transient motion. To account for the variance in the signal due to the experimental manipulation, we define regressors based on the design, as described in *protocol.txt*. *protocol.txt* says that blocks consisted of 12 trials, each 1.5s long, with 12s rest between blocks, and 6s rest at the start to let the scanner settle down. That 6s at the start was taken care of in the Data tab, so we have a design that looks like House, rest, Face, rest, House, rest, ...

We will specify this design using text files in FEAT's 3-column format: we make 1 text file per regressor, each with one line per period of time belonging to that regressor. Each line has 3 numbers, separated by whitespace. The first number indicates the onset time in seconds of the period. The second number indicates the duration of the period. The third number indicates the height of the regressor during the period; always set this to 1 unless you know what you're doing. See `FEAT's documentation`_ for more details.

.. _FEAT's documentation: http://www.fmrib.ox.ac.uk/fsl/feat5/detail.html#stats

These design files are provided for you. Make a directory to put them in, then download the files::

 $ mkdir design/run1
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_house1.txt >design/run1/house.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_face1.txt >design/run1/face.txt

Examine each of these files and refer to *protocol.txt* as necessary::

 $ less design/run1/house.txt
 $ less design/run1/face.txt

When making these design files for your own projects, do not use a Windows machine or you will likely have `problems with line endings`_.

.. _`problems with line endings`: http://en.wikipedia.org/wiki/Newline#Common_problems

To use these files to specify the design, click the "Full model setup" button. Set "EV name" to "house". FSL calls regressors EV's, short for Explanatory Variables. Set "Basic shape" to "Custom (3 column format)" and select *design/run1/house.txt*. That file on its own describes a square wave; to account for the shape of the BOLD response, we convolve it with another function that models the hemodynamic response to a stimulus. Set "Convolution" to "Double-Gamma HRF". Now to set up the face regressor set "Number of original EVs" to 2 and click to tab 2.

Set EV name to "face". Set "Basic shape" to "Custom (3 column format)" and select *design/face.txt*. Change "Convolution" to "Double-Gamma HRF", like we did for the house regressor.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/feat-stats-ev2.png

Now go to the "Contrasts & F-tests" tab. Increase "Contrasts" to 4. There is now a matrix of number fields with a row for each contrast and a column for each EV. You specify a contrast as a linear combination of the parameter estimates on each regressor. We'll make one contrast to show the main effect of the face regressor, one to show the main effect of the house regressor, one to show where the house regressor is greater than the face regressor, and one to show where the face regressor is greater:

* Set the 1st row's title to "house", its "EV1" value to 1, and its "EV2" value to 0. 
* Set the 2nd row's title to "face", its "EV1" value to 0, and its "EV2" value to 1. 
* Set the 3rd row's title to "house>face", its "EV1" value to 1, and its "EV2" value to -1. 
* Set the 4th row's title to "face>house", its "EV1" value to -1, and its "EV2" value to 1.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/feat-stats-contrasts-and-f-tests.png

Close that window, and FEAT shows you a graph of your model. If it's different from the one below, check you followed the instructions correctly.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/feat-model-graph.png

Go to the Post-stats tab.

**Summary**::

$ mkdir design/run1
$ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_house1.txt > design/run1/house.txt
$ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_face1.txt > design/run1/face.txt
$ less design/run1/house.txt
$ less design/run1/face.txt


The Post-stats tab
''''''''''''''''''''

As has been mentioned before, in the interest of saving space on Princeton's server (or in general), uncheck 'create time series plots' if you're not interested in seeing those plots. This will prevent a lot of unnecessary files from being made. Next, go to the registration tab.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/feat-poststats.png


The Registration tab
''''''''''''''''''''

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Different subjects have different shaped brains, and may have been in different positions in the scanner. To compare the data collected from different subjects, for each subject we compute the transformation that best moves and warps their data to match a standard brain, apply those transformations, then compare each subject in this "standard space". This Registration tab is where we set the parameters used to compute the transformation; we won't actually apply the transformation until we get to group analysis.

The subject's functional data is first registered to the initial structural image, then that is registered to the main structural image, which is then registered to the standard space image. All this indirection is necessary because registration can fail, and it's more likely to fail if you try to go directly from the functional data to standard space.

Another way to aid registration is by skull stripping the anatomical images that are used. To do that, run the FSL command 'bet' on both images:

$ bet data/nifti/0831101_confba02_t1_flash01.nii.gz data/nifti/0831101_confba02_t1_flash01_brain.nii.gz
$ bet data/nifti/0831101_confba02_t1_mprage01.nii.gz data/nifti/0831101_confba02_t1_mprage01_brain.nii.gz

FEAT should already have a "Standard space" image selected; leave it with the default, but change the drop-down menu from "Normal search" to "Full search", and set the other menu to "12 DOF" or this subject's brain will be misregistered. Check "Initial structural image", and select the file *data/nifti/0831101_confba02_t1_flash01_brain.nii.gz*. Keep the drop-down menu at "Normal search" and change the other menu to "6 DOF". Check "Main structural image", and select the file *data/nifti/0831101_confba02_t1_mprage01_brain.nii.gz*. Make sure "Normal search" and "6 DOF" are set for the main structural image as well.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/feat-registration.png

That's it! Hit Go. A webpage should open in your browser showing FEAT's progress. Once it's done, this webpage provides a useful summary of the analysis you just ran with FEAT. After making sure that no errors occurred during the analysis, let's continue hunting the PPA.

**Summary**::

$ bet data/nifti/0831101_confba02_t1_flash01.nii.gz data/nifti/0831101_confba02_t1_flash01_brain.nii.gz
$ bet data/nifti/0831101_confba02_t1_mprage01.nii.gz data/nifti/0831101_confba02_t1_mprage01_brain.nii.gz


Finding the PPA
---------------

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Launch FSLView::

  $ fslview

Click File>Open... and select *analysis/firstlevel/localizer_hrf.feat/mean_func.nii.gz*; this is an image of the mean signal intensity at each voxel over the course of the run. We use it as a background to overlay a contrast image on. Click File>Add... *analysis/firstlevel/localizer_hrf.feat/stats/zstat3.nii.gz*. *zstat3.nii.gz* is an image of z-statistics for the house>face contrast being different from 0, so high intensity values in a voxel indicate that the house regressor caught much more of the variance in fMRI signal at that voxel than the face regressor. To find the PPA, we'll look for regions with really high values in *zstat3.nii.gz*. To include only these regions in the overlay, set the Min threshold at the top of FSLView to something like 8, then click around in the brain to see what regions had contrast z-stats at that threshold or above. Look for a bilateral pair of regions with zstat's at a high threshold, around the middle of the brain; that'll be the PPA.

Repeating the analysis for a second run
========================================

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02
   
Now that you have analyzed one run of this subject's data, it's time to repeat the analysis on a second run. In many experiments, subjects will perform the same task in two identical runs so they have a bit of a break during the scanning session, or because different stimuli are counterbalanced across the scan session. The two runs can then be combined in a second-level analysis. This time around, we can do it more automatically. FEAT recorded all parameters of the analysis you just ran, in a file called *design.fsf* in its output directory, which was *analysis/firstlevel/localizer_hrf_01.feat/*. Our approach is to take that file, replace run-specific settings with placeholders, then for each new run, automatically substitute appropriate values for the placeholders, and run FEAT with the resulting file. 

Templating the fsf file
-----------------------

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

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
  #. on the line starting with "set fmri(custom1)", replace all of the text inside the quotes with "<?= $EV_DIR ?>/house.txt"
  #. on the line starting with "set fmri(custom2)", replace all of the text inside the quotes with "<?= $EV_DIR ?>/face.txt"

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

   ~/ppa-hunt2/subjects/0831101_confba02

Now, we have a template fsf file. To use that template, we need a script that fills it in, appropriately, for each run and for each subject. This filling-in process is called rendering, and a script that does most of the work is provided at *scripts/render-fsf-templates.sh*. Open that in your text editor::

$ nano scripts/render-fsf-templates.sh

It consists of a function called render_firstlevel, which we'll use to render the localizer template. Copy these lines as-is onto the end of that file, then save it::

  render_firstlevel $FSF_DIR/localizer_hrf.fsf.template \
                    $FIRSTLEVEL_DIR/localizer_hrf_01.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_localizer01 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01_brain.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage01_brain.nii.gz \
                    . \
                    . \
                    $EV_DIR/run1 \
                    > $FSF_DIR/localizer_hrf_01.fsf

  render_firstlevel $FSF_DIR/localizer_hrf.fsf.template \
                    $FIRSTLEVEL_DIR/localizer_hrf_02.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_localizer02 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01_brain.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage01_brain.nii.gz \
                    . \
                    . \
                    $EV_DIR/run2 \
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

   ~/ppa-hunt2/subjects/0831101_confba02

As we saw earlier, *prep.sh* already calls *render-fsf-templates.sh*. *analyze.sh* calls *prep.sh*, so to automate the analysis, all that remains is running *feat* on the rendered fsf file from a script that's called by *analyze.sh*. We'll make a new script called *localizer.sh* for that purpose. Make the script with this command::

  $ nano scripts/localizer.sh

Then fill it with this text::

  #!/bin/bash
  source globals.sh
  
  bet $NIFTI_DIR/${SUBJ}_t1_flash01.nii.gz $NIFTI_DIR/${SUBJ}_t1_flash01_brain.nii.gz
  bet $NIFTI_DIR/${SUBJ}_t1_mprage01.nii.gz $NIFTI_DIR/${SUBJ}_t1_mprage01_brain.nii.gz

  feat $FSF_DIR/localizer_hrf_01.fsf
  feat $FSF_DIR/localizer_hrf_02.fsf
  
The first line says that this is a BASH script. The second line loads variables from *globals.sh*. The next two lines skull strip the two anatomical images to be used for registration, and the last two lines call *feat*, which runs FEAT without the graphical interface. The argument passed to *feat* is the path to the fsf file for it to use. Notice that the path is specified with a variable "$FSF_DIR", which is defined in *globals.sh*.

Now that we have a script for running the GLM analysis, we'll call it from *analyze.sh* so that one command does the entire analysis. Open *analyze.sh* in your text editor::

 $ nano analyze.sh

After the line that runs *prep.sh*, add this line::

 bash scripts/localizer.sh

*analyze.sh* is linked to *~/prototype/link/analyze.sh*, so the change you just made will be reflected in *analyze.sh* in all current and future subject directories. Now we can test that it works. First, remove the finished analysis folder::

 $ rm -rf analysis/firstlevel/*
 
**Summary**::

  $ nano scripts/localizer.sh
  $ cp scripts/localizer.sh ../../prototype/link/scripts
  $ nano analyze.sh
  $ rm -rf analysis/firstlevel/*

Preparing for Feat
------------------

Before we start the analysis, we need the regressor files for house and face blocks for the second run, since the order of house and face blocks are different. These design files are provided for you. Make a directory to put them in, then download the files::

 $ mkdir design/run2
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_house2.txt >design/run2/house.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_face2.txt >design/run2/face.txt

Then, run our newly updated analysis that deals with both localizer runs::

 $ ./analyze.sh

Feat should be churning away, and two webpages should open in your browser showing FEAT's progress. There should be one feat folder for each run in *analysis/firstlevel*.

**Summary**::

 $ mkdir design/run2
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_house2.txt >design/run2/house.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831101_confba02_face2.txt >design/run2/face.txt
 $ ./analyze.sh

Collapsing across the two localizer runs
========================================

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Now that we have completed Feat analyses for the two localizer runs, it's time to combine the results of the two runs. We'll use FEAT again to run what it calls a "higher-level analysis", which combines the information from those "first-level" analyses that we just did. The process will be very similar to that in `GLM analysis with FEAT (first-level)`_. When running first-level analyses, we stored FEAT folders, scripts, and fsf files in the subjects's *analysis/firstlevel* folder; now that we're doing analyses that combine runs, we'll store all of those under *analysis/secondlevel*.


GLM analysis with FEAT (higher-level)
-------------------------------------

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Launch FEAT::

  $ Feat &


The Data tab
''''''''''''

Change the drop-down in the top left from "First-level analysis" to "Higher-level analysis". This will change the layout of the rest of the data tab. Set "Number of inputs" to 2, because we're combining 2 run analyses, then click "Select FEAT directories". For the first directory, select *analysis/firstlevel/localizer_hrf_01.feat*, and for the second, select *analysis/firstlevel/localizer_hrf_02.feat*. Set the output directory to *analysis/secondlevel/localizer_hrf*.

Go to the Stats tab.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/secondlevel-feat-data.png


The Stats tab
'''''''''''''

Change the first option to 'Fixed Effects,' and then click "Model setup wizard". Leave it on the default option of "single group average", and click "Process". That's it! Hit "Go" to run the analysis.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/secondlevel-feat-stats.png


Finding the subject's PPA
-----------------------

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

When the analysis finishes, open FSLview::

  $ fslview &

Click File>Open Standard and accept the default. Click File>Add, and select *analysis/secondlevel/localizer_hrf.gfeat/cope3.feat/stats/zstat1.nii.gz*. Set the minimum threshold to 6 or 7, and you should see the PPA in the same bilaterial posterior area as before.

**Summary**::

 $ Feat &
 $ fslview &
 
Templating the second-level analysis
------------------------------------

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02
   
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

Find the line that says "# 4D AVW data or FEAT directory (1)". Replace it and the next 4 lines (including spaces) with::

  <?php for ($i=0; $i < count($runs); $i++) { ?>
  # 4D AVW data or FEAT directory (<?= $i+1 ?>)
  set feat_files(<?= $i+1 ?>) "<?= $SUBJECTS_DIR ?>/analysis/firstlevel/<?= $runs[$i] ?>"

  <?php } ?>

That chunk of code will essentially replace the two groups of original code that set the second-level Feat directories. Then, similarly, find the line that says "# Higher-level EV value for EV 1 and input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($runs)+1; $i++) { ?>
  # Higher-level EV value for EV 1 and input <?= $i ?> 

  set fmri(evg<?= $i ?>.1) 1

  <?php } ?>

Again, the inserted PHP code should completely replace the two original blocks of code that dictate 'group membership' for each run. Since we are averaging across both runs, they will all belong to the same 'group'. Next, find the line that says "# Group membership for input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($runs)+1; $i++) { ?>
  # Group membership for input <?= $i ?> 

  set fmri(groupmem.<?= $i ?>) 1

  <?php } ?>

Save the file. Now, so that we have access to this file for future subjects, let's copy it to *prototype/copy*::

  $ cp fsf/localizer_hrf_secondlevel.fsf.template ../../prototype/copy/fsf/

**Summary**::

  $ cp analysis/secondlevel/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf_secondlevel.fsf.template
  $ nano fsf/localizer_hrf_secondlevel.fsf.template
  $ cp fsf/localizer_hrf_secondlevel.fsf.template ../../prototype/copy/fsf/

Automating the second-level analysis
------------------------------------

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Now that we have a template for the second-level localizer analysis fsf file, all that's left is to render it and run FEAT on the rendered fsf file. Open up the *localizer.sh* script we made earlier with your text editor::

  $ nano scripts/localizer.sh

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Copy these lines into localizer.sh at the end::
  
	# Wait for two first-level analyses to finish
	scripts/wait-for-feat.sh $FIRSTLEVEL_DIR/localizer_hrf_01.feat
	scripts/wait-for-feat.sh $FIRSTLEVEL_DIR/localizer_hrf_02.feat
	
	STANDARD_BRAIN=/usr/share/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
	
	pushd $SUBJECT_DIR > /dev/null
	subj_dir=$(pwd)
	
	# This function defines variables needed to render higher-level fsf templates.
	function define_vars {
	 output_dir=$1
	
	 echo "
	 <?php
	 \$OUTPUT_DIR = '$output_dir';
	 \$STANDARD_BRAIN = '$STANDARD_BRAIN';
	 \$SUBJECTS_DIR = '$subj_dir';
	 "
	
	 echo '$runs = array();'
	 for runs in `ls $FIRSTLEVEL_DIR/`; do
	   echo "array_push(\$runs, '$runs');";
	 done
	
	 echo "
	 ?>
	 "
	}
	
	# Form a complete template by prepending variable definitions to the template,
	# then render it with PHP and run FEAT on the rendered fsf file.
	fsf_template=$subj_dir/$FSF_DIR/localizer_hrf_secondlevel.fsf.template
	fsf_file=$subj_dir/$FSF_DIR/localizer_hrf_secondlevel.fsf
	output_dir=$subj_dir/analysis/secondlevel/localizer_hrf.gfeat
	define_vars $output_dir | cat - "$fsf_template" | php > "$fsf_file"
	feat "$fsf_file"
	
	cp -R $FIRSTLEVEL_DIR/localizer_hrf_01.feat/reg analysis/secondlevel/localizer_hrf.gfeat
	cp $FIRSTLEVEL_DIR/localizer_hrf_01.feat/example_func.nii.gz analysis/secondlevel/localizer_hrf.gfeat
	
	popd > /dev/null  # return to whatever directory this script was run from


If the text following "STANDARD_BRAIN=" differs from what you copied out of the fsf file in the previous section, replace it with that text you copied.

Save and close the script. To make this script available in future subject directories, copy it to the prototype::

 $ cp scripts/localizer.sh ../../prototype/link/scripts

Remember, *prototype/link* holds files that should be identical in each subject's directory. Any file in that directory will be linked into each new subject's directory: when a linked file is changed in one subject's directory (or in *prototype/link*), the change is immediately reflected in all other links to that file.

Now, let's run it to test that everything works::

  $ bash scripts/localizer.sh

A webpage should open in your browser showing FEAT's progress. Because we manually ran this analysis and put its output into *analysis/secondlevel/localizer_hrf.gfeat*, FEAT should have created a new directory at *analysis/secondlevel/localizer_hrf+.gfeat*, and should be showing you the analysis running in that directory.

**Summary**::

  $ nano scripts/localizer.sh
  $ bash scripts/localizer.sh

 
Repeating the analysis for a new subject
======================================== 

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Congratulations on analyzing your first subject with NeuroPipe! Now, we'll do it again, but much of the work has already been done. First, move back into the project directory::

 $ cd ../../
 
Now, scaffold a new subject. This subject is 0831102_confba02::

 $ ./scaffold 0831102_confba02

Then, move into that subject's directory::

 $ cd subjects/0831102_confba02
 
This subject's run-order file looks a bit different, so in this case putting a template in *prototype/copy* isn't helpful. The file has been made for you already::

  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_run-order.txt > run-order.txt

This subject's stimuli order was slightly different. Instead of beginning with face images, their first set of stimuli were house images. They therefore have different face and house regressor files. They're provided for you already::

  $ mkdir design/run1
  $ mkdir design/run2
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_house1.txt > design/run1/house.txt
  $ s
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_house2.txt > design/run2/house.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_face2.txt > design/run2/face.txt

We already made a template for the localizer run that works for different subjects, edited scripts/render-fsf-templates.sh to make a unique design file for each run, and created localizer.sh to run the two Feat analyses. Because we already copied these files into *~/protoype*, these changes will be present in the new subject's directory. All that's left is to collect the data and then run the analysis! First, get the subject's data (NOTE: you must be on rondo for this to work)::

  $ cp /jukebox/ntb/packages/neuropipe/example_data/0831102_confba02.raw.tar.gz data/raw.tar.gz

As before, it will prompt you to enter a password; email ntblab@princeton.edu to request access to this data.

Now, analyze it::

  $ ./analyze.sh

FEAT should be churning away on the new data. Take some time to look over the QA for the new data, and check out the results of the Feat analyses.

**Summary**::
 
  $ cd ../../
  $ ./scaffold 0831102_confba02
  $ cd subjects/0831102_confba02
  $ mkdir design/run1
  $ mkdir design/run2
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_house1.txt > design/run1/house.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_face1.txt > design/run1/face.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_house2.txt > design/run2/house.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_thirdlevel/0831102_confba02_face2.txt > design/run2/face.txt
  $ cp /jukebox/ntb/packages/neuropipe/example_data/0831102_confba02.raw.tar.gz data/raw.tar.gz
  $ ./analyze.sh


Combining within-subjects analyses into a group analysis
========================================================

.. admonition:: you are here

   ~/ppa-hunt2/subjects/0831101_confba02

Now that we've found the PPAs for two subjects individually, it's time to perform a group analysis to learn how reliable the PPA location is across these subjects. We'll use FEAT again to run what it calls a "higher-level analysis", which takes the information from those "first-level" analyses that we just did. The process will be very similar to that in `GLM analysis with FEAT (first-level)`_. When running within-subjects analyses, we stored FEAT folders, scripts, and fsf files in the subjects's folders; now that we're doing group analyses, we'll store all of those under *~/group*.


GLM analysis with FEAT (higher-level)
-------------------------------------

Move up to the root project folder, then to the group folder::

  $ cd ../../
  $ cd group

.. admonition:: you are here

   ~/ppa-hunt2/group

Launch FEAT::

  $ Feat &


The Data tab
''''''''''''

Change the drop-down in the top left from "First-level analysis" to "Higher-level analysis". This will change the stuff you see below. Set "Number of inputs" to 2, because we're combining 2 within-subjects analyses, then click "Select FEAT directories". Let's say we're interested in the house>scene contrast. Then, for the first directory, select *~/ppa-hunt2/subjects/0831101_confba02/analysis/secondlevel/localizer_hrf.gfeat/cope3.feat*, and for the second, select *~/ppa-hunt2/subjects/0831102_confba02/analysis/secondlevel/localizer_hrf.gfeat/cope3.feat*. Set the output directory to *~/ppa-hunt2/group/analysis/localizer_hrf*.

Go to the Stats tab.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/group-feat-data.png


The Stats tab
'''''''''''''

Click "Model setup wizard", leave it on the default option of "single group average", and click "Process". Keep the drop-down menu on 'Mixed Effecs: FLAME 1.' 


The Post-stats tab
''''''''''''''''''''

Again, in the interest of saving space on Princeton's server (or in general), uncheck 'create time series plots' if you're not interested in seeing those plots. That's it! Hit "Go" to run the analysis.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_thirdlevel/group-feat-stats.png

When the analysis is finished, check the logs to make sure everything looks normal -- for example, that the two subjects' brains were registered correctly to standard space.


Automating the group analysis
=============================

To automate the group analysis to work without additional effort when new subjects are added, we follow the same sort of procedure we did for within-subjects analyses: take the fsf file created when we manually ran FEAT, turn it into a template, write a script to render that template appropriately, then write a script to run FEAT on the rendered fsf file.


Templating the group fsf file
-----------------------------

.. admonition:: you are here

   ~/ppa-hunt2/

Just like when we ran a second-level analysis on two localizer runs for each subject, to template a higher-level fsf file, we'll need to repeat whole sections of the fsf file for each input going into the group analysis. In this case, each input is a subject instead of a run. Like before, we'll use PHP to render the templates, and write loops for those sections of the template that need repeating for each subject.

Start by copying the *design.fsf* file for the group analysis we just ran to *~/group/fsf*, and give it a ".template" extension::

  $ cp group/analysis/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf_thirdlevel.fsf.template

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
  set feat_files(<?= $i+1 ?>) "<?= $SUBJECTS_DIR ?>/<?= $subjects[$i] ?>/analysis/secondlevel/localizer_hrf.gfeat/cope3.feat"

  <?php } ?>

The inserted PHP code should replace two chunks of the original Feat code.  Find the line that says "# Higher-level EV value for EV 1 and input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($subjects)+1; $i++) { ?>
  # Higher-level EV value for EV 1 and input <?= $i ?>
  
  set fmri(evg<?= $i ?>.1) 1

  <?php } ?>

Again, the inserted PHP code should replace two chunks of the original Feat code. Now find the line that says "# Group membership for input 1". Replace it and the next 4 lines with::

  <?php for ($i=1; $i < count($subjects)+1; $i++) { ?>
  # Group membership for input <?= $i ?> 
  
  set fmri(groupmem.<?= $i ?>) 1

  <?php } ?>

Again, two sets of Feat code should have been replaced by the PHP code. Save the file.

**Summary**::

  $ cp analysis/localizer_hrf.gfeat/design.fsf fsf/localizer_hrf_thirdlevel.fsf.template
  $ nano fsf/localizer_hrf_thirdlevel.fsf.template 

Automating the group analysis
-----------------------------

.. admonition:: you are here

   ~/ppa-hunt2

Now that we have a template for the group localizer analysis fsf file, all that's left is to render it and run FEAT on the rendered fsf file. Make a file in *scripts* called *group-localizer.sh* with your text editor::

  $ nano scripts/group-localizer.sh

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
  fsf_template=$PROJECT_DIR/fsf/localizer_hrf_thirdlevel.fsf.template
  fsf_file=$PROJECT_DIR/fsf/localizer_hrf_thirdlevel.fsf
  output_dir=$PROJECT_DIR/$GROUP_DIR/analysis/localizer_hrf.gfeat
  define_vars $output_dir | cat - "$fsf_template" | php > "$fsf_file"
  feat "$fsf_file"

If the text following "STANDARD_BRAIN=" differs from what you copied out of the fsf file in the previous section, replace it with that text you copied.

Save and close the script, then run it to test that everything works::

  $ scripts/group-localizer.sh

A webpage should open in your browser showing FEAT's progress. Because we manually ran this analysis and put its output into *~/ppa-hunt2/group/analysis/localizer_hrf.gfeat*, FEAT should have created a new directory at *~/ppa-hunt2/group/analysis/localizer_hrf+.gfeat*, and be showing you the analysis running in that directory.

**Summary**::

  $ nano scripts/group-localizer.sh
  $ scripts/group-localizer.sh


Automating the entire analysis
==============================

.. admonition:: you are here

   ~/ppa-hunt2

Our goal was to run the entire analysis with a single command, to make it easy to reproduce. We're close. Open *analyze-group.sh* in your text editor::

  $ nano analyze-group.sh

You see that this script loads settings by sourcing *globals.sh*, runs each subject's individual analysis, then has a space for us to run scripts to do our group analysis. First, after the line that runs analyze.sh for each subject, add this line::

 $ bash scripts/wait-for-feat.sh $SUBJECTS_DIR/$subj/analysis/secondlevel/localizer_hrf.gfeat

That line makes the thirdlevel Feat analysis wait for both subjects' secondlevel analyses to finish before beginning. Finally, after the comment marking where to run group analyses, add this line::

 $ bash scripts/group-localizer.sh

Save and exit. That's it! To test this out, first delete any pre-existing subject and group analyses::

  $ rm -rf subjects/*/analysis/firstlevel/*
  $ rm -rf subjects/*/analysis/secondlevel/*
  $ rm -rf group/analysis/*

Now run the whole analysis::

  $ ./analyze-group.sh

**Summary**::

  $ nano analyze.sh
  $ rm -rf subjects/*/analysis/firstlevel/*
  $ rm -rf subjects/*/analysis/secondlevel/*
  $ rm -rf group/analysis/*
  $ ./analyze-group.sh
