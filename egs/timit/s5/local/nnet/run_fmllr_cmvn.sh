#!/bin/bash

# Copyright 2012-2014  Brno University of Technology (Author: Karel Vesely)
# Apache 2.0

# This example script trains a DNN on top of fMLLR features. 
# The training is done in 3 stages,
#
# 1) RBM pre-training:
#    in this unsupervised stage we train stack of RBMs, 
#    a good starting point for frame cross-entropy trainig.
# 2) frame cross-entropy training:
#    the objective is to classify frames to correct pdfs.
# 3) sequence-training optimizing sMBR: 
#    the objective is to emphasize state-sequences with better 
#    frame accuracy w.r.t. reference alignment.

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

# Config:
gmmdir=exp/tri3
data_fmllr=data-fmllr-tri3
stage=0 # resume training with --stage=N
# End of config.
. utils/parse_options.sh || exit 1;
#

if [ $stage -le 0 ]; then
  # Store fMLLR features, so we can train on them easily,
  # test
  dir=$data_fmllr/test
  steps/nnet/make_fmllr_feats.sh --nj 10 --cmd "$train_cmd" \
     --transform-dir $gmmdir/decode_test \
     $dir data/mfcc/test $gmmdir $dir/log $dir/data || exit 1
  # dev
  dir=$data_fmllr/dev
  steps/nnet/make_fmllr_feats.sh --nj 10 --cmd "$train_cmd" \
     --transform-dir $gmmdir/decode_dev \
     $dir data/mfcc/dev $gmmdir $dir/log $dir/data || exit 1
  # train
  dir=$data_fmllr/train
  steps/nnet/make_fmllr_feats.sh --nj 10 --cmd "$train_cmd" \
     --transform-dir ${gmmdir}_ali \
     $dir data/mfcc/train $gmmdir $dir/log $dir/data || exit 1
  # split the data : 90% train 10% cross-validation (held-out)
  utils/subset_data_dir_tr_cv.sh $dir ${dir}_tr90 ${dir}_cv10 || exit 1
  # compute cmvn
  steps/compute_cmvn_stats.sh $data_fmllr/train exp/make_fmlrr/train $data_fmllr
  steps/compute_cmvn_stats.sh $data_fmllr/dev exp/make_fmlrr/dev $data_fmllr
  steps/compute_cmvn_stats.sh $data_fmllr/test exp/make_fmlrr/test $data_fmllr
fi

echo Success
exit 0
