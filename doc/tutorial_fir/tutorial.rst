==================
NeuroPipe Tutorial
==================



:author: Alexa Tompary
:email: ntblab@princeton.edu



.. contents::



-----------------------------------------------
Chapter 4 - FIR analysis of an adaptation study
-----------------------------------------------

If you've worked through the introductory tutorial, you are ready to use this tutorial (no need to go through the HRF analysis tutorials to understand what's going on here).  In this study, you will be running an FIR analysis of a study for one subject. First, you will analyze the first subject's data, and then template the analysis workflow to use on the second subject's data. Then, you will run a second-level analysis that combines the data from both subjects, and create a template to automate the second-level analysis for future subjects.  

Before you begin, make sure that you have a copy of your project folder (here, it's called 'fir-proj'). 

Using a FIR model to analyze fMRI data is useful when you 1) are looking to fit as much of your brain data as possible into a model, and 2) do not want to make any assumptions about the shape of the brain's response to your stimuli. This task looks for subdued brain response, or 'adaptation,' when subjects are shown repeated patterns of scene images.  Since the response to these patterns may not look like the canonical hemodynamic response, we'll go with an FIR model instead. In this analysis, we will pick a time window around each trial, and run a GLM to model the response at several time points within the window.

Analyzing a subject
===================

We'll start by analyzing a single subject. First, we will create a folder to hold all of the subjects' data, analyses, and results. Then, will convert the brain data to a FSL-compatible format and run some quality assurance tests. Finally, we'll set up the GLM model using FSL's Feat program.


Setting up
----------

.. admonition:: you are here

   ~/fir-proj

Our subject ID is "0223101_conatt01", so run this command::

  $ ./scaffold 0223101_conatt01

*scaffold* tells you that it made a subject directory at *subjects/0223101_conatt01* and that you should read the README.txt file there if this is your first time setting up a subject. Move into the subject's directory, and do what it says::

  $ cd subjects/0223101_conatt01
  $ less README.txt

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

This *README.txt* says your first step is to get some DICOM data and put it in a Gzipped TAR archive at *data/raw.tar.gz*. This data has already been collected for you. Hit "q" to quit *README.txt* and get the data with this command (NOTE: you must be on rondo for this to work)::

  $ cp /jukebox/ntb/packages/neuropipe/example_data/0223101_conatt01.raw.tar.gz data/raw.tar.gz

Email ntblab@gmail.com to request access to this data if you cannot access it on your own. NOTE: *cp* just copies files, and here we've directed it to copy data that was prepared for this tutorial; it doesn't work in general to retrieve data after you've done a scan. On rondo at Princeton, you can use *~/prototype/link/scripts/retrieve-data-from-sun.sh* (which appears at *~/subjects/SUBJ/scripts/retrieve-data-from-sun.sh*) to get your data, as long as your subject's folder name matches the subject ID used during for your scan session.

**Summary**::

  $ ./scaffold 0223101_conatt01
  $ cd subjects/0223101_conatt01
  $ less README.txt
  $ cp /jukebox/ntb/packages/neuropipe/example_data/0223101_conatt01.raw.tar.gz data/raw.tar.gz

Preparing your data for analysis
--------------------------------

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

Open *README.txt* again::

  $ less README.txt

Next, we need to fill out *run-order.txt* with the order of MRI sequences that were completed for this subject. One has already been made for you, so go ahead and run this command to get it:: 

 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/run-order.txt > run-order.txt

To check that *run-order.txt* came through all right, hit "q" to get out of *README.txt*, and run this command::

 $ less run-order.txt
 
You will see that some scans that aren't relevant to this tutorial have been marked with 'ERROR_RUN' so they will not be unzipped and prepped for analysis. Now, put a copy of *run-order.txt* in *prototype/copy/*. That directory is special. Any file or folder in it will be copied into each new subject directory that's created by *scaffold*::

 $ cp run-order.txt ../../prototype/copy/run-order.txt
 
Let's take another look at *README.txt* to see what to do next::

 $ less README.txt

It says that we should proceed by doing various transformations on the data, and then running a quality assurance tool to make sure the data is usable. The transformations make the data more palatable to FSL_, which we will use for analysis. As *README.txt* says, you do all that with the command *analyze.sh*. Before running that, see what it does::

  $ less analyze.sh

.. _FSL: http://www.fmrib.ox.ac.uk/fsl/

Look at the body of the script, and notice it just runs another script: *prep.sh*. Hit "q" to quit *analyze.sh* and read *prep.sh*::

  $ less prep.sh

*prep.sh* calls four other scripts: one to do those transformations on the data, one to run the quality assurance tools, one to perform some more transformations on the data, and one called *render-fsf-templates.sh*. Don't worry about that last one for now--we'll cover it later. If you'd like, open those first three scripts to see what they do. Otherwise, press on::

  $ ./analyze.sh

Once *analyze.sh* completes (and it may take awhile, since it's doing so many tasks), look around *data/nifti*::

  $ ls data/nifti

There should be a pair of .bxh/.nii.gz files for each pulse sequence listed in *run-order.txt*, excluding the sequences called ERROR_RUN. Open the .nii.gz files with FSLView_, if you'd like, using a command like this::

  $ fslview data/nifti/0223101_conatt01_t1_mprage01.nii.gz

.. _FSLView: http://www.fmrib.ox.ac.uk/fsl/fslview/index.html

There's also a new folder at *data/qa*. Peek in and you'll see a ton of files. These are organized by an HTML file at *data/qa/index.html*. Open it with this command::

  $ firefox data/qa/index.html

Use the "(What's this?)" links to figure out what all the diagnostics mean. When then diagnostics have convinced you that there are no quality issues with this data (such as lots of motion) that would make it uninterpretable, close firefox.

**Summary**::

  $ less README.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/run-order.txt > run-order.txt
  $ less run-order.txt
  $ less README.txt
  $ less analyze.sh
  $ less prep.sh
  $ ./analyze.sh
  $ ls data/nifti
  $ fslview data/nifti/0223101_conatt01_t1_mprage01.nii.gz
  $ firefox data/qa/index.html


GLM analysis with FEAT (first-level)
------------------------------------

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

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

~/fir-proj/subjects/0223101_conatt01

Click "Select 4D data" and select the file *data/nifti/0223101_conatt01_encoding01.nii.gz*; FEAT will analyze this data. Set "Output directory" to *analysis/firstlevel/encoding_fir01*; FEAT will put the results of its analysis in this folder, but with ".feat" appended, or "+.feat" appended if this is the second analysis with this name that you've run. FEAT should have detected "Total volumes" as 355, but it may have mis-detected "TR (s)" as 3.0; if so, change that to 1.5, because this experiment had a TR length of 1.5 seconds. Because *protocol.txt* indicated there were 9 seconds of disdaqs (volumes of data at the start of the run that are discarded because the scanner needs a few seconds to settle down), and TR length is 1.5s, set "Delete volumes" to 6. Set "High pass filter cutoff (s)" to 128 to remove slow drifts from your signal.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_fir/feat-data.png

Go to the Pre-stats tab.


The Pre-stats tab
'''''''''''''''''

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

Change "Slice timing correction" to "Interleaved (0,2,4 ...", because slices were collected in this interleaved pattern. Leave the rest of the settings at their defaults.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_fir/feat-pre-stats.png

Go to the Stats tab.


The Stats tab
'''''''''''''

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

Check "Add motion parameters to model"; this makes regressors from estimates of the subject's motion, which hopefully absorb variance in the signal due to transient motion. To account for the variance in the signal due to the experimental manipulation, we define regressors based on the design, as described in *protocol.txt*. *protocol.txt* says that subjects viewed an uninterrupted stream of images, making an indoor/outdoor decision for one image every 1.5 seconds.

Unbeknownst to the participants, the images were structured in such a way that each image fell into 1 of 12 categories determined by the structure of preceding images. We are going to focus on 4 of the catgories of images, and therefore will have 4 regressors in this model (NC_NFI, NC_RFI, RC_NFI, and RC_RFI). If you are interested in hearing about the details of this study's design, please email ntblab@princeton.edu.

We will specify this design using text files in FEAT's 3-column format: we make 1 text file per regressor, each with one line per stimulus occurance belonging to that regressor. Each line has 3 numbers, separated by whitespace. The first number indicates the onset time in seconds of the period. The second number indicates the duration of the period. The third number indicates the height of the regressor during the period; always set this to 1 unless you know what you're doing. See `FEAT's documentation`_ for more details.

.. _FEAT's documentation: http://www.fmrib.ox.ac.uk/fsl/feat5/detail.html#stats

These design files are provided for you. Make a directory to put them in, then download the files::

 $ mkdir design/encoding1
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/NC_NFI.txt > design/encoding1/NC_NFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/NC_RFI.txt > design/encoding1/NC_RFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/RC_NFI.txt > design/encoding1/RC_NFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/RC_RFI.txt > design/encoding1/RC_RFI.txt

Examine some of these files and check out the format::

 $ less design/encoding1/NC_NFI.txt

When making these design files for your own projects, do not use a Windows machine or you will likely have `problems with line endings`_.

.. _`problems with line endings`: http://en.wikipedia.org/wiki/Newline#Common_problems

To use these files to specify the design, click the "Full model setup" button. Set number of original EVs to 4. FSL calls regressors EV's, short for Explanatory Variables. We will go through how to set up the first EV, and then you can set up the other 3 in the same format.

Click on Tab 1. Set one EV name to match the name of one of our text files. In this case, we'll use NC_NFI. Set "Basic shape" to "Custom (3 column format)" and select *design/encoding1/NC_NFI.txt*. That file on its own describes a square wave; to apply the FIR parameters that we discussed earlier, we will set "Convolution" to "FIR basis function" and specify the number and duration of "impulses" that will be sampled for each stimulus onset. Set "Number" to 12 and "Window(s)" to 18. Now to set up the second regressor, click to tab 2. Complete each regressor with the same parameters, changing only the EV Name and the file used. Use this order of regressors: NC_NFI, NC_RFI, RC_NFI, RC_RFI::

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_fir/feat-stats-ev4.png

Now go to the "Contrasts & F-tests" tab. Increase "Contrasts" to 5. There is now a matrix of number fields with a row for each contrast and a column for each EV. You specify a contrast as a linear combination of the parameter estimates on each regressor. We'll make one contrast to show the main effect of each regressor, and also one to look at the difference in brain activity between certain regressors. The idea here is that you can look at the differences between regressors or even groups of regressors by creating a contrast for a particular relationship you're interested in:

* Set the 1st row's title to "NC_NFI", its "EV1" value to 1, and leave the rest of the EV values at 0. 
* Set the 2nd row's title to "NC_RFI", its "EV2" value to 1, and leave the rest at 0.
* Set the 3rd row's title to "RC_NFI", its "EV3" value to 1, and leave the rest at 0.
* Set the 4rd row's title to "RC_RFI", its "EV4" value to 1, and leave the rest at 0.
* Set the 5th row's title to "NC_RFI-RC_RFI", its "EV2" value to 1, its "EV4" value to -1, and leave the rest at 0. 

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_fir/feat-stats-contrasts.png

Click 'Done', and FEAT shows you a graph of your model. If it's different from the one below, check you followed the instructions correctly.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_fir/feat-graph-model.png

The Post-stats tab
''''''''''''''''''''

Go to the post-stats tab. Again, in the interest of saving space on Princeton's server (or in general), uncheck 'create time series plots' if you're not interested in seeing those plots.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_fir/feat-poststats.png

Go to the Registration tab.

**Summary**::

 $ mkdir design/encoding1
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/NC_NFI.txt > design/encoding1/NC_NFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/NC_RFI.txt > design/encoding1/NC_RFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/RC_NFI.txt > design/encoding1/RC_NFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding1/RC_RFI.txt > design/encoding1/RC_RFI.txt
 $ less design/encoding1/NC_NFI.txt

The Registration tab
''''''''''''''''''''

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

Different subjects have different shaped brains, and may have been in different positions in the scanner. To compare the data collected from different subjects, for each subject we compute the transformation that best moves and warps their data to match a standard brain, apply those transformations, then compare each subject in this "standard space". This Registration tab is where we set the parameters used to compute the transformation; we won't actually apply the transformation until we get to group analysis.

The subject's functional data is first registered to the initial structural image, then that is registered to the main structural image, which is then registered to the standard space image. All this indirection is necessary because registration can fail, and it's more likely to fail if you try to go directly from the functional data to standard space.

FEAT should already have a "Standard space" image selected; leave it with the default settings. Check "Initial structural image", and select the file *subjects/0223101_conatt01/data/nifti/0223101_conatt01_t1_flash01.nii.gz*. Change the drop-down menu from "7 DOF" to "3 DOF (translation only)", or this subject's functional brain will be mis-matched to its initial structual image. Check "Main structural image", and select the file *subjects/0223101_conatt01/data/nifti/0223101_conatt01_t1_mprage01.nii.gz*.

.. image:: https://github.com/ntblab/neuropipe-support/raw/rc-0.3/doc/tutorial_fir/feat-reg.png

That's it! Hit Go. A webpage should open in your browser showing FEAT's progress. Once it's done, this webpage provides a useful summary of the analysis you just ran with FEAT. Before continuing on, be sure to check through the logs to make sure that no errors have occured.


Repeating the analysis for a second run
========================================

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01
   
Now that you have analyzed one run of this subject's data, it's time to repeat the analysis on a second run. In many experiments, subjects will perform the same task in two identical runs so they have a bit of a break during the scanning session, or because different stimuli are counterbalanced across the scan session. The two runs can then be combined in a second-level analysis. This time around, we can do it more automatically. FEAT recorded all parameters of the analysis you just ran, in a file called *design.fsf* in its output directory, which was *analysis/firstlevel/encoding_fir01.feat/*. Our approach is to take that file, replace run-specific settings with placeholders, then for each new run, automatically substitute appropriate values for the placeholders, and run FEAT with the resulting file. 

Templating the fsf file
-----------------------

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

Start by copying the *design.fsf* file for the analysis we just ran to *fsf*, and give it a ".template" extension::

  $ cp analysis/firstlevel/encoding_fir01.feat/design.fsf fsf/encoding-fir.fsf.template

We'll keep fsf files and their templates in this *fsf* folder. Now, open *fsf/encoding-fir.fsf.template* in your favorite text editor. If you don't have a favorite, try this::

  $ nano fsf/encoding-fir.fsf.template

Make the following replacements and save the file. Be sure to include the spaces after "<?=" and before "?>". ::
 
  #. on the line starting with "set fmri(outputdir)", replace all of the text inside the quotes with "<?= $OUTPUT_DIR ?>"
  #. on the line starting with "set fmri(regstandard) ", replace all of the text inside the quotes with "<?= $STANDARD_BRAIN ?>"
  #. on the line starting with "set feat_files(1)", replace all of the text inside the quotes with "<?= $DATA_FILE_PREFIX ?>"
  #. on the line starting with "set initial_highres_files(1) ", replace all of the text inside the quotes with "<?= $INITIAL_HIGHRES_FILE ?>"
  #. on the line starting with "set highres_files(1)", replace all of the text inside the quotes with "<?= $HIGHRES_FILE ?>"
  #. on the line starting wth "set fmri(custom1)", replace all the text inside the quotes with "<?= $EV_DIR ?>/NC_NFI.txt"
  #. on the line starting wth "set fmri(custom2)", replace all the text inside the quotes with "<?= $EV_DIR ?>/NC_RFI.txt"
  #. on the line starting wth "set fmri(custom3)", replace all the text inside the quotes with "<?= $EV_DIR ?>/RC_NFI.txt"
  #. on the line starting wth "set fmri(custom4)", replace all the text inside the quotes with "<?= $EV_DIR ?>/RC_RFI.txt"


Those bits you replaced with placeholders are the parameters that must change when analyzing a different run, a new subject, or using a different computer. After saving the file, copy it to the prototype so it's available for future subjects::

  $ cp fsf/encoding-fir.fsf.template ../../prototype/copy/fsf/

Recall that the *prototype/copy* holds files that should initially be the same, but may need to vary between subjects. We put the fsf file there because it may need to be tweaked for future subjects - to fix registration problems, for instance.

**Summary**::

  $ cp analysis/firstlevel/encoding_fir01.feat/design.fsf fsf/encoding-fir.fsf.template
  $ nano fsf/encoding-fir.fsf.template
  $ cp fsf/encoding-fir.fsf.template ../../prototype/copy/fsf/
 
Rendering the template
----------------------

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

Now, we have a template fsf file. To use that template, we need a script that fills it in, appropriately, for each run and for each subject. This filling-in process is called rendering, and a script that does most of the work is provided at *scripts/render-fsf-templates.sh*. Open that in your text editor::

$ nano scripts/render-fsf-templates.sh

It consists of a function called render_firstlevel, which we'll use to render the localizer template. Copy these lines as-is onto the end of that file, then save it::

  render_firstlevel $FSF_DIR/encoding-fir.fsf.template \
                    $FIRSTLEVEL_DIR/encoding_fir01.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_encoding01 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage01.nii.gz \
                    . \
                    . \
                    $EV_DIR/encoding1 \
                    > $FSF_DIR/encoding_fir01.fsf

  render_firstlevel $FSF_DIR/encoding-fir.fsf.template \
                    $FIRSTLEVEL_DIR/encoding_fir02.feat \
                    $FSL_DIR/data/standard/MNI152_T1_2mm_brain \
                    $NIFTI_DIR/${SUBJ}_encoding02 \
                    $NIFTI_DIR/${SUBJ}_t1_flash01.nii.gz \
                    $NIFTI_DIR/${SUBJ}_t1_mprage01.nii.gz \
                    . \
                    . \
                    $EV_DIR/encoding2 \
                    > $FSF_DIR/encoding_fir02.fsf
                    
That hunk of code calls the function render_firstlevel, passing it the values to substitute for the template's placeholders. Each chunk of code will create a new design.fsf file, one for each localizer run. This will be useful when analyzing the next subject's data. The values in this script use a bunch of completely-uppercase variables, which are defined in *globals.sh*.  Examine *globals.sh*::

  $ less globals.sh

*scripts/convert-and-wrap-raw-data.sh* needs to know where to look for the subject's raw data, and where to put the converted and wrapped data. *scripts/qa-wrapped-data.sh* needs to know where that wrapped data was put. To avoid hardcoding that information into each script, those locations are defined as variables in *globals.sh*, which each script then loads. By building the call to render_firstlevel with those variables, we won't need to modify it for each subject, and if you ever change the structure of your subject directory, all you must do is modify *globals.sh* to reflect the changes.

**Summary**::

  $ nano scripts/render-fsf-templates.sh
  $ less globals.sh
  
Automating the analysis
-----------------------

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

As we saw earlier, *prep.sh* already calls *render-fsf-templates.sh*. *analyze.sh* calls *prep.sh*, so to automate the analysis, all that remains is running *feat* on the rendered fsf file from a script that's called by *analyze.sh*. We'll make a new script called *encoding.sh* for that purpose. Make the script with this command::

  $ nano scripts/encoding.sh

Then fill it with this text::

  #!/bin/bash
  source globals.sh
  feat $FSF_DIR/encoding_fir01.fsf
  feat $FSF_DIR/encoding_fir02.fsf
  
The first line says that this is a BASH script. The second line loads variables from *globals.sh*. The the last two lines call *feat*, which runs FEAT without the graphical interface. The argument passed to *feat* is the path to the fsf file for it to use. Notice that the path is specified with a variable "$FSF_DIR", which is defined in *globals.sh*.

To make this script available in future subject directories, copy it to the prototype::

 $ cp scripts/encoding.sh ../../prototype/link/scripts

Remember, *prototype/link* holds files that should be identical in each subject's directory. Any file in that directory will be linked into each new subject's directory: when a linked file is changed in one subject's directory (or in *prototype/link*), the change is immediately reflected in all other links to that file.

Now that we have a script for running the GLM analysis, we'll call it from *analyze.sh* so that one command does the entire analysis. Open *analyze.sh* in your text editor::

 $ nano analyze.sh

After the line that runs *prep.sh*, add this line::

 bash scripts/encoding.sh

*analyze.sh* is linked to *~/prototype/link/analyze.sh*, so the change you just made will be reflected in *analyze.sh* in all current and future subject directories. Now we can test that it works. First, remove the finished analysis folder::

 $ rm -rf analysis/firstlevel/*
 
The second encoding run for this subject requires its own set of regressor files, since the order of images is different in the two runs. Grab the encoding files for the second run::

 $ mkdir design/encoding2
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/NC_NFI.txt > design/encoding2/NC_NFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/NC_RFI.txt > design/encoding2/NC_RFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/RC_NFI.txt > design/encoding2/RC_NFI.txt
 $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/RC_RFI.txt > design/encoding2/RC_RFI.txt

Then, run our newly updated analysis that deals with both encoding runs::

 $ ./analyze.sh

Feat should be churning away, and two webpages should open in your browser showing FEAT's progress. There should be one feat folder for each run in *analysis/firstlevel*.

**Summary**::

  $ nano scripts/encoding.sh
  $ cp scripts/encoding.sh ../../prototype/link/scripts
  $ nano analyze.sh
  $ rm -rf analysis/firstlevel/*
  $ mkdir design/encoding2
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/NC_NFI.txt > design/encoding2/NC_NFI.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/NC_RFI.txt > design/encoding2/NC_RFI.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/RC_NFI.txt > design/encoding2/RC_NFI.txt
  $ curl -k https://raw.github.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_fir/encoding2/RC_RFI.txt > design/encoding2/RC_RFI.txt
  $ ./analyze.sh


What comes next
---------------

.. admonition:: you are here

   ~/fir-proj/subjects/0223101_conatt01

You now have information about this subject's response to different regressors, in an 18 second window consisting of 12 timepoints. From here, your analysis will vary according to the aims of your study. Furthermore, because we copied the scripts used in this analysis in the *prototype* folders, you are now in a position to analyze more subject data simply by collecting data, creating run-specific regressor files, and running *analyze.sh*.

If you're also interested in extracting timecourse information from specific regions of interest within the brain, you can check out the ROI tutorial and use the data you've just analyzed.