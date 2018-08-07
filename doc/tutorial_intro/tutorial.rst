==================
NeuroPipe Tutorial
==================



:author: Mason Simon
:email: ntblab@princeton.edu



.. contents::



---------------------------------------------------------
Chapter 1 - Understanding neuropipe and its prerequisites
---------------------------------------------------------


Introduction
============

NeuroPipe is a framework for reproducible fMRI analysis projects with FSL. It's designed for group (across-subjects) analyses built on top of within-subjects analyses that are mainly identical. If this (or a subset of it) describes your project, NeuroPipe will help you implement your analyses and run them with a single command. This simplifies debugging, by letting you quickly make a fix and test it. And, it lets others re-run your analysis to verify your work is correct, or to build upon your project once you've finished it.

This quick introduction walks you through the structure of neuropipe, what you need to know in order to use it, and how to set it up for the study of your choice. After reading this introduction, you can then use the more advanced tutorials to work through several types of analyses:

- secondlevel_: a within-subjects analysis on one subject, repeating that analysis for a second subject, and then running a group analysis across both of these subjects
- thirdlevel_: a within-subjects analysis on two subjects, where a within-subject higher-level analysis needs to be completed before running a group analysis
- FIR_: analysis for one subject using finite impulse basis functions, with a within-subject higher-level analysis
- ROI_: an explanation of how time-course information from specific regions of interest can be extracted from functional runs

.. _secondlevel: https://github.com/ntblab/neuropipe-support/blob/rc-0.3/doc/tutorial_secondlevel/tutorial.rst
.. _thirdlevel: https://github.com/ntblab/neuropipe-support/blob/rc-0.3/doc/tutorial_thirdlevel/tutorial.rst
.. _FIR: https://github.com/ntblab/neuropipe-support/blob/rc-0.3/doc/tutorial_fir/tutorial.rst
.. _ROI: https://github.com/ntblab/neuropipe-support/blob/rc-0.3/doc/tutorial_roi/tutorial.rst

Prerequisites
-------------

NeuroPipe is built with UNIX commands and BASH scripts. If you're unfamiliar with those, this tutorial may confuse you. Invest some time into learning UNIX and shell scripting; it will yield good returns. Try starting with `Unix Third Edition: Visual Quickstart Guide`_, which you can read for free online if you're at Princeton.

.. _`Unix Third Edition: Visual Quickstart Guide`: http://proquest.safaribooksonline.com/0321442458 

You should be ok if you understand:

- how to run programs from the UNIX command line,
- how to move around the directory tree with *cd*,
- relative pathnames, and
- symbolic links.

In addition to basic familiarity with the UNIX command line, you'll need access to a UNIX-based computer (Mac OSX or any flavor of Linux should work), with git_, `BXH XCEDE tools`_, and FSL_ installed. If you're at Princeton, use rondo_, which has all the necessary tools installed. If not, you'll have to download these packages and modify the pathnames in *prototype/link/globals.sh* to source the correct packages. You'll only have to do it once for each project you begin.

.. _git: http://git-scm.com/
.. _`BXH XCEDE tools`: http://www.birncommunity.org/tools-catalog/bxhxcede-tools/
.. _FSL: http://www.fmrib.ox.ac.uk/fsl/
.. _rondo: http://cluster-wiki.pni.princeton.edu/dokuwiki/

In this tutorial, you use git to track changes to the example project. A full explanation of git and version control systems is beyond the scope of the tutorial, so if you're unfamiliar with those, read chapters 1 and 2 of `Pro Git`_.

.. _`Pro Git`: http://progit.org/book/


Conventions used in these tutorials
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
 
- Note for those that are working on these tutorials on rondo: when you've qrsh'ed onto a node, you cannot download files from github. So, anytime you use the curl command to retrieve files for the tutorial, make sure you are on the head node (exit out of the node you've been assigned). You can qrsh back to a node to run the rest of the analyses.

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

.. _here: http://docs.google.com/viewer?url=http%3A%2F%2Fgithub.com%2Fntblab%2Fneuropipe-support%2Fraw%2Fdev%2Fdoc%2Farchitecture.pdf

A note about using example data
-------------------------------

Because the data used in these tutorials may be personally identifiable, these data are subject to privacy restrictions and are not available on github. If you are working outside of Princeton University and would like to use these files, please contact ntblab@princeton.edu. If you are working within the university but outside of the Turk-Browne lab, you can find it on the ntb partition on rondo at /exanet/ntb/packages/neuropipe/example_data. Contact ntblab@princeton.edu if you are unable to access it due to permissions restrictions.


Setting up your NeuroPipe project
=================================

.. admonition:: you are here

   ~/

NeuroPipe is a sort of skeleton for fMRI analysis projects using FSL. To work with it, you download that skeleton, then flesh it out.

First, log in to your UNIX terminal. If you're at Princeton, that means log in to rondo; look at `the access page on the rondo wiki`_ if you're not sure how. (Do not qrsh, otherwise you cannot retrieve files from github using curl).

.. _`the access page on the rondo wiki`: http://cluster-wiki.pni.princeton.edu/dokuwiki/wiki:access

We'll use git to grab the latest copy of NeuroPipe. But before that, configure git with your current name, email, and text editor of choice (if you haven't already)::

  $ git config --global user.name "YOUR NAME HERE"
  $ git config --global user.email "YOUR_EMAIL@HERE.COM"
  $ git config --global core.editor nano

Now, using git, download NeuroPipe into a folder called *ppa-hunt*, and set it up::

  $ git clone git://github.com/ntblab/neuropipe.git ppa-hunt
  $ cd ppa-hunt
  $ git checkout -b ppa-hunt origin/rc-0.3

Look around::

  $ ls

.. admonition:: you are here

   ~/ppa-hunt

You should see, among other things, a *README.txt* file, a command called *scaffold*, a file called *protocol.txt*, and a directory called *prototype*. Start by reading *README.txt*::

  $ less README.txt

The first instruction in the Getting Started section is to open *protocol.txt* and follow its instructions. Hit "q" to quit *README.txt*, then open *protocol.txt*::

  $ less protocol.txt

It says to fill it in with details on the data collection protocol. We'll just download a *protocol.txt* file that describes the ppa-hunt data you can analyze in later tutorials. Hit "q" to quit out of *protocol.txt*, then run these commands::

  $ rm protocol.txt
  $ curl -k https://raw.githubusercontent.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_intro/protocol.txt > protocol.txt

Read that newly downloaded *protocol.txt*::

  $ less protocol.txt

Hit "q", and open *README.txt* again::

  $ less README.txt

The next instruction is to open *prototype/copy/run-order.txt*. Hit "q", then read that file::

  $ less prototype/copy/run-order.txt

As with *protocol.txt*, a *run-order.txt* file is already made for you. Download that file, and put it where *README.txt* says::

  $ curl -k https://raw.githubusercontent.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_intro/run-order.txt > prototype/copy/run-order.txt

Open this new *run-order.txt* to see what it's like now::

  $ less prototype/copy/run-order.txt

Some runs are marked as "ERROR_RUN" so that only the runs relevant to your analysis remain.

Quit *run-order.txt* with "q", and open *README.txt* one last time::

  $ less README.txt

Next, it's time to collect some subject data and run some analyses. From here, you can choose to follow one or more of the more advanced tutorials listed above.

**Summary**::

  $ git clone http://github.com/ntblab/neuropipe.git ppa-hunt 
  $ cd ppa-hunt
  $ git checkout -b ppa-hunt origin/rc-0.3
  $ ls
  $ less README.txt
  $ less protocol.txt
  $ rm protocol.txt
  $ curl -k https://raw.githubusercontent.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_intro/protocol.txt > protocol.txt
  $ less protocol.txt
  $ less README.txt
  $ less prototype/copy/run-order.txt
  $ curl -k https://raw.githubusercontent.com/ntblab/neuropipe-support/rc-0.3/doc/tutorial_intro/run-order.txt > prototype/copy/run-order.txt
  $ less prototype/copy/run-order.txt
  $ less README.txt
