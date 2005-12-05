# -* sh *-
. lib-vidprofile
 
# profile
# A script that profiles a given input video with mpeg2enc. Multiple tests
# are run with different encoder flags and statistics on output file size 
# and encoding times are taken.
#
# Command line options allow the output files to be kept or a specific
# frame to be captured from the output files, or both! Also, the Peak
# Signal to Noise Ratio may be calculated. 
#
# Please see the discussion on the tovid forums for further details:
# http://www.createphpbb.com/phpbb/viewtopic.php?p=462&mforum=tovid#462
#
# Usage:
#
# $ profile -f video.avi
#
# Pass profile a video file, and go get some coffee (and maybe a good book).
#
# TO-DO:
# (1) Adapt for long movies: allow inpoints and outpoints

# Copyright (C) 2005 Joe Friedrichsen <pengi.films@gmail.com>
# Original script pieces by Eric Pierce.
# Modified on 2005 September 23.
# 
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation; either 
# version 2 of the License, or (at your option) any later 
# version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 
 
# ******************************************************************************
# ******************************************************************************
#
#
# CONSTANTS
#
#
# ******************************************************************************
# ******************************************************************************
 
# Base mpeg2enc format: 4:3 29.97fps NTSC DVD
MP2_FIXED="-a 2 -n n -f 8 -F 4"
 
MPLAYER_OPTS="-benchmark -nosound -noframedrop -noautosub -vf scale=720:480"
 
# A counter for data points collected during the test. Initialize.
DATA_POINTS=0

# Flags for data processing the control test (see post_test)
VARIABLE_TEST=0
CONTROL_TEST=1

# Count how many times the control test has happened
CONTROL_ITER=0

# List of PIDS to kill on exit
PIDS=""

# Number of fields in test specifications
FLAG_LENGTH=1
SINGLE_LENGTH=4
DUAL_LENGTH=8

USAGE=`cat << EOF

profile $VIDPROFILE_VERSION (build options: $BUILD_OPTS)

Usage: profile [OPTIONS] -f /path/to/video.avi

  -f, -file /path/to/video.avi        video to profile
  -l, -logfile /path/to/logfile.csv   where to put the data log
  -el, -errlog /path/to/error.log     where to put the error log
  -nl, -enclog /path/to/encoder.log   where to put the encoding log
  -pl, -psnrlog /path/to/psnr.csv     where to put the PSNR log
  -t, -test "TEST"                    run TEST
  -t, -test "TEST 1:TEST 2:TEST 3"    run TEST 1, TEST 2, TEST 3
      "-FLAG"                         test an mpeg2enc flag
      "-OPTION MIN MAX STEP"          test numerical options
      "-OPT1 MIN1 MAX1 STEP1 -OPT2 MIN2 MAX2 STEP2"
   -c, -config /path/to/config.file   use a custom config file
   -k, -keepvids                      keep encoded videos
   -nf, -encframe NUMBER              only encode to frame NUMBER
   -p, -psnr NUMBER|all               find the PSNR for NUMBER|all frames
   -s, -snapshot NUMBER               take a snaphot of frame NUMBER
   -h, -help                          display help and exit
   -v, -version                       print version and exit
 
See also
  man profile
  
EOF`


 
 
# ******************************************************************************
# ******************************************************************************
#
#
# DEFAULTS
#
#
# ******************************************************************************
# ******************************************************************************
 
PROFILE_HOME=$VIDPROFILE_HOME

# Logs
LOGFILE=$PROFILE_HOME/profile.csv         # Data
ERROR_LOG=/dev/null                       # Errors for short processes (mv, rm ...)
ENC_LOG=/dev/null                         # mplayer and mpeg2enc output (very long!)
PSNR_FRAME_LOG=$PROFILE_HOME/psnr.csv     # pnmpsnr output (long)

# Not reading a config file yet
# The default config file is read every time
READING_CONFIG=false
CONFIG_FILE="$PROFILE_HOME/profile.conf"

# No tests to run
# Individual tests are separated by colons (:)
TEST_LIST=""
 
# How many frames should mplayer send to mpeg2enc?
# To encode the entire input file, comment these lines, or set the the number of
# frames to more than the frames in the input file.
# 450 frames play just longer than 15sec (NTSC) or 18sec (PAL)
LAST_FRAME=""
MPLAYER_FRAMES=""

# Keep the movies mpeg2enc creates? [:|false]
# The script leaves the movies in the same directory from which it was called.
KEEP_OUTFILES=false
 
# Take a frame from each test? [:|false]
# If so, which one? (be sure it's less than either the number of frames mplayer sends
#   to mpeg2enc, above, or the amount of frames in the entire input file).
# The script leaves the snapshots in the same directory from which it was called.
TAKE_SNAP=false
SNAP_FRAME=""

# Find the Peak Signal to Noise Ratio? [:|false]
# If so, where should frames (in ppm format) be dropped? (they will be removed at the end)
#        where should the frame-by-frame PSNR log be dropped?
#        how many frames should be compared? (comment for all. NOTE: each frame is about 1MB)
FIND_PSNR=false
PSNR_CONT_DIR=/tmp/psnr-control
PSNR_COMP_DIR=/tmp/psnr-compare
PSNR_FRAMES=""
PSNR_MPLAY_FRAMES=""

# Set-up mplayer output format for PSNR
CONT_PNM="pnm:outdir=$PSNR_CONT_DIR"
COMP_PNM="pnm:outdir=$PSNR_COMP_DIR"
 
 
 

# ******************************************************************************
# ******************************************************************************
#
#
# FUNCTIONS
#
#
# ******************************************************************************
# ******************************************************************************

# Trap Ctrl-C and TERM to clean up child processes
trap 'killsubprocs; exit 13' TERM INT
 
# ******************************************************************************
# Kill child processes
# ******************************************************************************
killsubprocs()
{
  echo
  precho "Profile stopped, killing all sub-processes"
  eval "kill $PIDS"
  rm_output
  clean_up
}    

# ******************************************************************************
# Read all command-line arguments, and read any arguments included in the
# default configuration file (if it exists)
# ******************************************************************************
get_args()
{
  # Parse all arguments
  while test $# -gt 0; do
      case "$1" in
          "-v" | "-version" )
              precho "profile $VIDPROFILE_VERSION (build options: $BUILD_OPTS)"
              exit 0
              ;;
      
          # Use custom config file?
          "-c" | "-config" )
              # Read in name of config file
              shift
              CONFIG_FILE="$1"
              echo
              precho "Overriding default configuration file (if it exists)."
              read_config
              ;;
          
          # Main data log file
          "-l" | "-logfile" )
              shift
              LOGFILE="$1"
              ;;
          
          # Error log file
          "-el" | "-errlog" )
              shift
              ERROR_LOG="$1"
              ;;
                
          # Encoder log file
          "-nl" | "-enclog" )
              shift
              ENC_LOG="$1"
              ;;
                
          # Encode only the first N frames? How many?
          "-nf" | "-encframe" )
              shift
              LAST_FRAME="$1"
              MPLAYER_FRAMES="-frames $LAST_FRAME"
              ;;

          # Keep encoded videos?
          "-k" | "-keepvids" )
              KEEP_OUTFILES=:
              ;;
                
          # Take a snapshot from each video? Which one?
          "-s" | "-snapshot" )
              shift
              TAKE_SNAP=:
              SNAP_FRAME="$1"
              ;;
                
          # Find the PSNR? Use how many frames?
          "-p" | "-psnr" )
              check_optional_dependency "pnmpsnr" "-p"
              shift
              FIND_PSNR=:
              PSNR_FRAMES="$1"
              if test "x$PSNR_FRAMES" = "xall"; then
                  PSNR_MPLAY_FRAMES=""
              else
                  PSNR_MPLAY_FRAMES="-frames $PSNR_FRAMES"
              fi
              ;;
                
          # PSNR log file
          "-pl" | "-psnrlog" )
              check_optional_dependency "pnmpsnr" "-pl"
              shift
              PSNR_FRAME_LOG="$1"
              ;;
              
          # A profile test
          "-t" | "-test" )
              # Find which test has been given
              shift
              TEST_LIST="$TEST_LIST:$1"
              ;;
          
          # Print usage guide
          "-h" | "-help" )
              precho -e "$USAGE"
              exit 0
              ;;
            
          "-f" | "-file" )
              shift
              # Get a full pathname for the infile
              D=`dirname "$1"`
              B=`basename "$1"`
              INFILE="`cd \"$D\" && pwd || echo \"$D\"`/$B"
              ;;
 
          # Null option; ignored.
          "-" )
              ;;

          # If the option wasn't recognized, exit with an error
          * )
              exit_with_error "Error: Unrecognized command-line option $1. (try -help)"
              ;;
          esac

      # Get next argument
      shift
  done
}

# ******************************************************************************
# Read the default configuration file
# 
# ******************************************************************************
read_config()
{
  # check that a config file exists and is readable
  if test -r "$CONFIG_FILE"; then
     # Make sure file is a profile config file
     CONFIG_TYPE=`head -n 1 "$CONFIG_FILE"`
     if test x"$CONFIG_TYPE" != x"profile"; then
        echo
        precho "$CONFIG_FILE is not a valid profile configuration file. Skipping it."
     else
        READING_CONFIG=:
        CONFIG_ARGS=`grep '^-' $CONFIG_FILE | tr '\n' ' '`
        precho "Using config file $CONFIG_FILE, containing the following options:"
        if test -n "$CONFIG_ARGS"; then
           precho "$CONFIG_ARGS"
           eval get_args "$CONFIG_ARGS"
        else
           precho "(none)"
        fi
     fi
  fi
}

# ******************************************************************************
# Validate input arguments
# 
# ******************************************************************************
check_input()
{
  # Make sure profile can take a snapshot and find the PSNR

  # Does the input file exist?
  if test -e "$INFILE"; then :
     else exit_with_error "Error: could not find infile \"$INFILE\""; fi
    
  # If taking a snapshot ($SNAP_FRAME has been set)
  if test x$SNAP_FRAME != x; then
     # Give a warning if an encoding limit hasn't been given.
     if test -z $LAST_FRAME; then
        echo
        precho "Warning: Taking a snapshot of frame $SNAP_FRAME when no explicit encode frame limit (-nf NUMBER; refer to \"profile -h\") is given. If `basename \"$INFILE\"` has less than $SNAP_FRAME frames, then this will fail."
        echo
     # Else report an error if the snapshot frame is greater than the encode frame limit.
     else
        if test $SNAP_FRAME -gt $LAST_FRAME; then
           exit_with_error "Error: cannot take a snapshot of frame $SNAP_FRAME, only $LAST_FRAME frames will be encoded."
        fi
     fi
  fi
  
  # If finding the PSNR (but not using all frames), give a warning if the
  # PSNR frames are greater than the encoded frame limit.
  if test x$PSNR_FRAMES != x && test x$PSNR_FRAMES != xall && \
     test x$LAST_FRAME != x && \
     test $PSNR_FRAMES -gt $LAST_FRAME; then
        echo
        precho "Warning: The given number of frames for the PSNR calculation ($PSNR_FRAMES) is more than the number of frames that will be encoded ($LAST_FRAME). The entire video will be used to find the PSNR."
        echo
  fi
    
  # Minimal test specification check: is the length ok?
  #                                   does the test start with -?
  # Whether or not an option takes a numerical argument is not checked.
  #   eg -H 0 5 1 would break profile (-H is a flag!)
  # Whether or not a range with a decimal point is consistent is not checked.
  #   eg -N 0 2 0.1 would break profile (needs to be -N 0.0 2.0 0.1)
  i=2
  while test $i -le `echo "$TEST_LIST" | awk -F ':' '{ print NF }'`; do
     TEST=`echo $TEST_LIST | awk -F ':' "{ print $"$i" }"`
     TEST_TYPE=`echo "$TEST" | awk '{ print NF }'`
     if test $TEST_TYPE -ne $FLAG_LENGTH && \
        test $TEST_TYPE -ne $SINGLE_LENGTH && \
        test $TEST_TYPE -ne $DUAL_LENGTH || \
        ! echo "$TEST" | grep ^- >> /dev/null 2>> $ERROR_LOG
     then exit_with_error "Error: Unrecognized test $TEST. (try -help)" 
     fi
     i=`expr $i + 1`
  done
}

# ******************************************************************************
# Set up the profile
# 
# ******************************************************************************
set_up()
{
  SCRIPT_START=`date +%c`
 
  # Gather input video file information
  FILE_ID=`md5sum $INFILE`
    
  VID_SPECS=`mplayer -vo null -ao null -frames 1 -identify "$INFILE" 2>>$ERROR_LOG | grep -A 20 ID_FILENAME`     
    
  # Find the length of the video to test    
  if test -z $LAST_FRAME; then
     DURATION=`echo "$VID_SPECS" | grep "LENGTH" | awk -F '=' '{ print $2 }'`
  else
     FPS=`echo "$VID_SPECS" | grep "FPS" | awk -F '=' '{ print $2 }'`
     DURATION=`echo "scale=2; $LAST_FRAME/$FPS" | bc -l`
  fi
    
  snap_shot "$INFILE"
    
  echo
  precho "md5sum:            $FILE_ID"
  precho "Video Duration:    $DURATION sec"
  precho "mpeg2enc baseline: $MP2_FIXED"
  echo
    
  # Put a new header in the data log
  touch "$LOGFILE"
  echo "\"Profile time:\",       \"$SCRIPT_START\""  >> "$LOGFILE"
  echo "\"md5sum:\",             \"$FILE_ID\"" >> "$LOGFILE"
  echo "\"Test baseline:\",      \"mpeg2enc $MP2_FIXED\"" >> "$LOGFILE"
  echo  >> "$LOGFILE"
  echo "\"Profile Parameters:\"" >> "$LOGFILE"
    
  i=2
  while test $i -le `echo "$TEST_LIST" | awk -F ':' '{ print NF }'`; do
     TEST=`echo $TEST_LIST | awk -F ':' "{ print $"$i" }"`
     echo "                    \"$TEST\"" >> "$LOGFILE"
     i=`expr $i + 1`
  done
  echo >> "$LOGFILE"
            
  # Logfile headers for data columns
  echo "\"Option 1\", \"Option 1 Value\", \"Option 2\", \"Option 2 Value\", \"Video Duration (s)\", \"Encoding time (s)\", \"Output size (kB)\", \"Time Multiplier\", \"Output Bitrate (kbps)\", \"Normalized Time (%)\", \"Normalized Bitrate (%)\", \"PSNR (dB)\"" >> "$LOGFILE"
    
  # Put a new header in the error log
  touch "$ERROR_LOG"
  echo "Profile time:       $SCRIPT_START"  >> "$ERROR_LOG"
  echo "md5sum:             $FILE_ID" >> "$ERROR_LOG"
  echo "Test baseline:      mpeg2enc $MP2_FIXED" >> "$ERROR_LOG"
  echo  >> "$ERROR_LOG"  
    
  # Put a new header in the encoding log
  touch "$ENC_LOG"
  echo "Profile time:       $SCRIPT_START"  >> "$ENC_LOG"
  echo "md5sum:             $FILE_ID" >> "$ENC_LOG"
  echo "Test baseline:      mpeg2enc $MP2_FIXED" >> "$ENC_LOG"
  echo  >> "$ENC_LOG"  
    
  # Prepare for PSNR
  if $FIND_PSNR; then
     mkdir $PSNR_CONT_DIR
     mkdir $PSNR_COMP_DIR

     mplayer $MPLAYER_OPTS $PSNR_MPLAY_FRAMES -vo $CONT_PNM "$INFILE" >> "$ENC_LOG" 2>&1

     # Put a new header in the psnr log
     touch "$PSNR_FRAME_LOG"
     echo "\"Profile time:\",       \"$SCRIPT_START\""  >> "$PSNR_FRAME_LOG"
     echo "\"md5sum:\",             \"$FILE_ID\"" >> "$PSNR_FRAME_LOG"
     echo "\"Test baseline:\",      \"mpeg2enc $MP2_FIXED\"" >> "$PSNR_FRAME_LOG"
     echo  >> "$PSNR_FRAME_LOG"  
  fi
}
 
# ******************************************************************************
# Run the control test, only the base parameters
# Args: $1 is the unique output file name identifier for the control file
# ******************************************************************************
control()
{
  CONTROL_ID="$1"
  CONTROL_ITER=`expr $CONTROL_ITER + 1`
 
  pre_test
    
  OUTFILE="control_${CONTROL_ID}"
  CMD="$MP2_FIXED -o $OUTFILE.mpg"
  
  encode
  post_test  
  CONTROL_PSNR=`calc_psnr`
  snap_shot "$OUTFILE.mpg"
  rm_output
  
  echo "\"CONTROL $CONTROL_ITER\", \"CONTROL $CONTROL_ITER\", \"CONTROL $CONTROL_ITER\", \"CONTROL $CONTROL_ITER\", \"$DURATION\", \"$TOT_TIME\", \"$FINAL_SIZE\", \"$TIME_MULT\", \"$BITRATE\", \"$NORM_TIME\", \"$NORM_BITR\", \"$CONTROL_PSNR\"" >> "$LOGFILE"
}
 
# ******************************************************************************
# Run a test on an option that takes an integer value
# Args: $1 $2 $3 $4 = [option] [min] [max] [step]
# ******************************************************************************
range_test()
{
  TEST_OPT=$1
  VAR=$2
  TEST_MAX=$3
  STEP=$4
 
  while :
  do
    pre_test
    
    OUTFILE="profiler_${TEST_OPT}_${VAR}"
    CMD="$MP2_FIXED $TEST_OPT $VAR -o $OUTFILE.mpg"
    
    encode
    post_test
    PSNR=`calc_psnr`
    snap_shot "$OUTFILE.mpg"
    rm_output
 
    echo "\"null\", \"null\", \"$TEST_OPT\", \"$VAR\", \"$DURATION\", \"$TOT_TIME\", \"$FINAL_SIZE\", \"$TIME_MULT\", \"$BITRATE\", \"$NORM_TIME\", \"$NORM_BITR\", \"$PSNR\"" >> "$LOGFILE"
    
    if test $VAR = $TEST_MAX; then break; fi

    VAR=`echo "$VAR + $STEP" | bc -l`
  done
}
 
# ******************************************************************************
# Run a test on two options that take integer values
# Args: $1 $2 $3 $4 \ = [option1] [min1] [max1] [step1] \
#       $5 $6 $7 $8   = [option2] [min2] [max2] [step2]
# ******************************************************************************
dual_range()
{
  TEST_OPT1=$1
  TEST_MIN1=$2
  TEST_MAX1=$3
  STEP1=$4
  
  TEST_OPT2=$5
  TEST_MIN2=$6
  TEST_MAX2=$7
  STEP2=$8
  
  VAR1=$TEST_MIN1
  VAR2=$TEST_MIN2
  
  while :
  do
    
    while :
    do
      pre_test
      
      OUTFILE="profiler_${TEST_OPT1}_${VAR1}_${TEST_OPT2}_${VAR2}"
      CMD="$MP2_FIXED $TEST_OPT1 $VAR1 $TEST_OPT2 $VAR2 -o $OUTFILE.mpg"
      
      encode
      post_test
      PSNR=`calc_psnr`
      snap_shot "$OUTFILE.mpg"
      rm_output
      
      echo "\"$TEST_OPT1\", \"$VAR1\", \"$TEST_OPT2\", \"$VAR2\", \"$DURATION\", \"$TOT_TIME\", \"$FINAL_SIZE\", \"$TIME_MULT\", \"$BITRATE\", \"$NORM_TIME\", \"$NORM_BITR\", \"$PSNR\"" >> "$LOGFILE"
     
      if test $VAR2 = $TEST_MAX2; then break; fi
      
      VAR2=`echo "$VAR2 + $STEP2" | bc -l`
    done
      
    VAR2=$TEST_MIN2
    
    if test $VAR1 = $TEST_MAX1; then break; fi
    
    VAR1=`echo "$VAR1 + $STEP1" | bc -l`
  done
}
 
# ******************************************************************************
# Run a test on an option that is only a flag (takes no value)
# Args: $1 = [option]
# ******************************************************************************
flag_test()
{
  FLAG=$1
 
  pre_test
  
  OUTFILE="profiler_${FLAG}"
  CMD="$MP2_FIXED $FLAG -o $OUTFILE.mpg"
  
  encode
  post_test
  PSNR=`calc_psnr`
  snap_shot "$OUTFILE.mpg"
  rm_output
 
  echo "\"null\", \"null\", \"$FLAG\", \"null\", \"$DURATION\", \"$TOT_TIME\", \"$FINAL_SIZE\", \"$TIME_MULT\", \"$BITRATE\", \"$NORM_TIME\", \"$NORM_BITR\", \"$PSNR\"" >> "$LOGFILE"
}
 
# ******************************************************************************
# Run a test on two options that take integer values, and where one option must
# always be greater than or equal to the other
# Args: $1 $2 $3 $4 \ = [option1] [min1] [max1] [step1] \
#       $5 $6 $7 $8     [option2] [min2] [max2] [step2]
# In this function, option1 >= option2 (G >= g).
# ******************************************************************************
G_g_test()
{
  TEST_OPT1=$1
  TEST_MIN1=$2
  TEST_MAX1=$3
  STEP1=$4
  
  TEST_OPT2=$5
  TEST_MIN2=$6
  TEST_MAX2=$7
  STEP2=$8
  
  VAR1=$TEST_MIN1
  VAR2=$TEST_MIN2
 
  while test $VAR1 -le $TEST_MAX1; do
    
    while test $VAR2 -le $VAR1; do
      pre_test
      
      OUTFILE="profiler_${TEST_OPT1}_${VAR1}_${TEST_OPT2}_${VAR2}"
      CMD="$MP2_FIXED $TEST_OPT1 $VAR1 $TEST_OPT2 $VAR2 -o $OUTFILE.mpg"
      
      encode
      post_test
      PSNR=`calc_psnr`
      snap_shot "$OUTFILE.mpg"
      rm_output
      
      echo "\"$TEST_OPT1\", \"$VAR1\",  \"$TEST_OPT2\", \"$VAR2\", \"$DURATION\", \"$TOT_TIME\", \"$FINAL_SIZE\", \"$TIME_MULT\", \"$BITRATE\", \"$NORM_TIME\", \"$NORM_BITR\", \"$PSNR\"" >> "$LOGFILE"
 
      VAR2=`expr $VAR2 + $STEP2`
    done
    
    VAR2=$TEST_MIN2
    VAR1=`expr $VAR1 + $STEP1`
  done
}
 
# ******************************************************************************
# Clean up the profile
# 
# ******************************************************************************
clean_up()
{
  # Remove frames (and directories) if finding the PSNR
  if $FIND_PSNR; then
     rm -f $PSNR_CONT_DIR/*.ppm
     rmdir $PSNR_CONT_DIR
     rm -f $PSNR_COMP_DIR/*.ppm
     rmdir $PSNR_COMP_DIR
     
     echo  >> "$PSNR_FRAME_LOG"  
     echo  >> "$PSNR_FRAME_LOG"  
  fi

  rm -f stream.yuv
  echo  >> "$LOGFILE"
  echo  >> "$LOGFILE"
  
  echo  >> "$ERROR_LOG"
  echo  >> "$ERROR_LOG"
  
  echo  >> "$ENC_LOG"
  echo  >> "$ENC_LOG"
}  
  
# ******************************************************************************
# Print a summary of the profile
# 
# ******************************************************************************
print_summary()
{
  SCRIPT_END=`date +%c`
  echo
  echo
  precho "All finished profiling `basename \"$INFILE\"` with mpeg2enc."
  precho "You have $DATA_POINTS new data points! (in $LOGFILE)"
  if $KEEP_OUTFILES; then precho "And output movies! (in `pwd`)"; fi
  if $TAKE_SNAP; then precho "And output stills! (in `pwd`)"; fi
  precho "I started on       $SCRIPT_START"
  precho "and finished on    $SCRIPT_END."
  echo
}
 
# ******************************************************************************
# Clean up before running an encoding test.
# Make note of the start time.
# ******************************************************************************
pre_test()
{
  rm -f stream.yuv >> "$ERROR_LOG" 2>&1
  mkfifo stream.yuv >> "$ERROR_LOG" 2>&1

  START_TIME=`date +%s`
}
 
# ******************************************************************************
# Encode the video.
# 
# ******************************************************************************
encode()
{
  printf '%-80s\r' "Testing $CMD"
  mplayer $MPLAYER_OPTS $MPLAYER_FRAMES -vo yuv4mpeg "$INFILE" >> "$ENC_LOG" 2>&1 &
  PIDS="$PIDS $!"
  cat stream.yuv | mpeg2enc $CMD >> "$ENC_LOG" 2>&1
  wait
}
 
# ******************************************************************************
# Clean up after running an encoding test.
# Make note of the encoding time and output file's size.
# ******************************************************************************
post_test()
{
  # Prepare output stats for the log
  END_TIME=`date +%s`
  TOT_TIME=`echo "scale=2; $END_TIME-$START_TIME" | bc -l`
  FINAL_SIZE=`du -k "$OUTFILE.mpg" | awk '{print $1}'`
  TIME_MULT=`echo "scale=2; $TOT_TIME/$DURATION" | bc -l`
  BITRATE=`echo "scale=0; 8*$FINAL_SIZE/$DURATION" | bc -l`
  
  # Things to do on first control test only:
  # Find the base control figures (bitrate and encoding time)
  if test $CONTROL_ITER -eq 1
  then
    CONT_TIME=$TOT_TIME
    CONT_BITR=$BITRATE
  fi    
  
  NORM_TIME=`echo "scale=2; ((100*$TOT_TIME/$CONT_TIME)-100)" | bc -l`
  NORM_BITR=`echo "scale=2; ((100*$BITRATE/$CONT_BITR)-100)" | bc -l`
  
  DATA_POINTS=`expr $DATA_POINTS + 1`
}
 
# ******************************************************************************
# Take a snapshot of a movie.
# Args: $1 = file to take a snapshot of.
# ******************************************************************************
snap_shot()
{
  SNAPFILE="$1"
  if $TAKE_SNAP; then
     SSNAME=`basename $SNAPFILE`
     mplayer $MPLAYER_OPTS -vo png -frames `expr $SNAP_FRAME + 1` "$SNAPFILE" >> "$ENC_LOG" 2>&1
     sleep 2
     mv 0*$SNAP_FRAME.png "frame-$SNAP_FRAME-$SSNAME.png" >> "$ERROR_LOG" 2>&1
     rm -f 0*.png >> "$ERROR_LOG" 2>&1
  fi
}
 
# ******************************************************************************
# Find the Peak-Signal-to-Noise Ratio between the source video and the
# endcoded video.
# ******************************************************************************
calc_psnr()
{
  if $FIND_PSNR; then
     mplayer -nosound -benchmark -noframedrop -noautosub $PSNR_MPLAY_FRAMES -vo $COMP_PNM "$OUTFILE.mpg" >> "$ENC_LOG" 2>&1
     echo "\"Finding PSNR between the source file and $OUTFILE.mpg\"" >> $PSNR_FRAME_LOG
     echo "`psnrcore -o \"$PSNR_CONT_DIR\" -c \"$PSNR_COMP_DIR\" -l \"$PSNR_FRAME_LOG\"`"
  else
     echo "not measured"
  fi
}

# ******************************************************************************
# Clean up the encoded movie.
# 
# ******************************************************************************
rm_output()
{
  if $KEEP_OUTFILES; then :
  else
      rm -f "$OUTFILE.mpg" >> "$ERROR_LOG" 2>&1
  fi
}
 
 
 
 
# ******************************************************************************
# ******************************************************************************
#
#
# MAIN
#
#
# ******************************************************************************
# ******************************************************************************

make_home
read_config 
get_args "$@"

check_input
set_up
control start

# While there are tests to run, get the next test and determine which test to call
i=2
while test $i -le `echo "$TEST_LIST" | awk -F ':' '{ print NF }'`; do
   TEST=`echo $TEST_LIST | awk -F ':' "{ print $"$i" }"`
   TEST_TYPE=`echo "$TEST" | awk '{ print NF }'`
   case "$TEST_TYPE" in
        "$FLAG_LENGTH" )
            flag_test $TEST
            ;;
        "$SINGLE_LENGTH" )
            range_test $TEST
            ;;
        "$DUAL_LENGTH" )
            if echo "$TEST" | awk '{ print $1 }' | grep '\-[gG]' >> /dev/null 2>&1 && \
               echo "$TEST" | awk '{ print $5 }' | grep '\-[gG]' >> /dev/null 2>&1
            then
               G_g_test $TEST
            else
               dual_range $TEST
            fi
            ;;
   esac
   i=`expr $i + 1`
done

control end
clean_up
print_summary
 
exit 0