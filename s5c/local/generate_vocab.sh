#!/bin/bash

export LC_ALL=C
MCdict='/ws/ifp-53_1/hasegawa/lsari2/data/mcasr/fromWenda/dict_grapheme.txt'
g2pdatadir=data/Uyghur/local/g2p
model_order=3
pron_variants=5

. ./path.sh || exit 1;
. utils/parse_options.sh || exit 1;


if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <mc-vocab/dict> <G2P-model> <phone-set> <g2p-data-dir>"
  echo "e.g.: $0 /ws/ifp-53_1/hasegawa/lsari2/data/mcasr/fromWenda/dict_grapheme.txt data/Uyghur/local/g2p"
  exit 1
fi
# if [ "$#" -eq 5 ]; then
#     model_order=$5
# fi
 
MCdict=$1
g2pmodeldir=$2
phoneset=$3
g2pdatadir=$4

mkdir -p $g2pdatadir


[ -f $MCdict ] || { echo "Nonsense words $MCdict does not exist" ; exit 1; }

echo "Model order and number of pronunciation variants for G2P application: $model_order $pron_variants"

g2pmodel=$g2pmodeldir/model-$model_order
for f in $g2pmodel $phoneset; do
    [ -f $f ] || { echo "$0: $f does not exist" ; exit 1; }
    # copy g2p model and the phone-set
    cp $f ${g2pdatadir}
done

if [ ! -f $g2pdatadir/vocab.plain ];then
# first column contains the words
awk '{print $1 }' $MCdict | sort | uniq > $g2pdatadir/vocab.all
# Rm words starting with numbers, rm punctuation marks
egrep -v '^[^a-z]' $g2pdatadir/vocab.all | tr -d '[:punct:]' \
    | uniq >  $g2pdatadir/vocab.plain
fi

# Assuming that G2P is already trained
# cp phoneset and G2P model

ls $g2pmodel

./local/g2p.sh $g2pdatadir/vocab.plain ${g2pdatadir} $g2pdatadir/lexicon_autogen.1 $model_order $pron_variants

