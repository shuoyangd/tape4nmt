import "tapes/packages.tape"
import "tapes/submitters.tape"
import "tapes/versioners.tape"

# ==== pipeline starts here ====

# download all the data to the local directory
import "tapes/download.tape"

# perform masking on reserved symbols to improve consistency 
import "tapes/mask.tape"

# perform masking on reserved symbols to improve consistency 
import "tapes/fast_align.tape"

# tasks related to tokenize
import "tapes/tokenize.tape"

# tasks related to casing
import "tapes/recase.tape"

# tasks related to subword processing
import "tapes/subword.tape"

# tasks related to subword processing
import "tapes/source_factors.tape"

# task binarize_data, train and decode fits in here in the execution order
# these tasks are usually the ones that needs to be defined for each toolkit
import "tapes/sockeye.tape"

# the order here is the reverse of the preprocessing
# usually: debpe -> detruecase -> detokenize
# if you need nist-bleu, you'll have to wrap up output into xml as well
import "tapes/postprocessing.tape"

# currently support nist_bleu and multi_bleu
# sacrebleu to be supported
import "tapes/bleu.tape"

# ==== pipeline ends here ====

# Nuts and bolts:
global {
  ducttape_experimental_packages=true
  ducttape_experimental_submitters=true
  ducttape_experimental_imports=true
  ducttape_experimental_multiproc=true
}

