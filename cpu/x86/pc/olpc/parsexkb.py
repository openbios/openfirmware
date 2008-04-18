#!/usr/bin/python
# parsekbd.py
# Usage:  python parsekbd.py OLPC_Nigeria_Keyboard
#
# Gets the wiki page (e.g.) http://wiki.laptop.org/go/OLPC_Nigeria_Keyboard
# Parses the keyboard table contained therein and converts it to a KA
# tag per http://wiki.laptop.org/go/Manufacturing_Data#Keyboard_ASCII_Map.
#
# The output is stored in a file named (e.g.) OLPC_Nigeria_Keyboard.ka
#
# Warnings on standard output tell you if duplicate entries are discarded
# or if some ASCII characters are not present.
#
# In a few cases, this program substitutes dead_{grave,circumflex,tilde}
# for {grave,asciicircumflex,asciitilde} because the ascii versions are
# in inaccessible locations (the firmware has only shift, unshift, AltGr
# maps, so a Shift-AltGr symbol is inaccessible).

from sys import *
from urllib import *
from re import *

saved_keyname = 128*[0]
keys = 128*[0]
modifiers = 128*[0]

# Map from xkb key names to scanset 1 "make" codes
keynames = {
'AB01':44,
'AB02':45,
'AB03':46,
'AB04':47,
'AB05':48,
'AB06':49,
'AB07':50,
'AB08':51,
'AB09':52,
'AB10':53,
'AB11':115,
'I219':115,
'AC01':30,
'AC02':31,
'AC03':32,
'AC04':33,
'AC05':34,
'AC06':35,
'AC07':36,
'AC08':37,
'AC09':38,
'AC10':39,
'AC11':40,
'BKSL':43,
'AD01':16,
'AD02':17,
'AD03':18,
'AD04':19,
'AD05':20,
'AD06':21,
'AD07':22,
'AD08':23,
'AD09':24,
'AD10':25,
'AD11':26,
'AD12':27,
'TLDE':41,
'AE01':2,
'AE02':3,
'AE03':4,
'AE04':5,
'AE05':6,
'AE06':7,
'AE07':8,
'AE08':9,
'AE09':10,
'AE10':11,
'AE11':12,
'AE12':13
};

# Convert from textual names of punctuation characters to the ASCII character
punctuation = {
  'exclam':ord('!'),
  'at':ord('@'),
  'numbersign':ord('#'),
  'dollar':ord('$'),
  'percent':ord('%'),
  'asciicircum':ord('^'),
  'dead_circumflex':ord('^'),
  'ampersand':ord('&'),
  'asterisk':ord('*'),
  'parenleft':ord('('),
  'parenright':ord(')'),
  'underscore':ord('_'),
  'plus':ord('+'),
  'minus':ord('-'),
  'equal':ord('='),
  'semicolon':ord(';'),
  'colon':ord(':'),
  'apostrophe':ord('\''),
  'grave':ord('`'),
  'dead_grave':ord('`'),
  'quotedbl':ord('"'),
  'dblquote':ord('"'),
  'bar':ord('|'),
  'less':ord('<'),
  'greater':ord('>'),
  'period':ord('.'),
  'slash':ord('/'),
  'backslash':ord('\\'),
  'question':ord('?'),
  'comma':ord(','),
  'bracketleft':ord('['),
  'bracketright':ord(']'),
  'braceleft':ord('{'),
  'braceright':ord('}'),
  'asciitilde':ord('~') ,
  'dead_tilde':ord('~') ,
  'backspace':8,
  'space':32,
  'tab':9,
  'linefeed':10,
  'enter':13,
  'esc':27,
  'escape':27,
  'del':127,
  'delete':127,
  '&amp;':ord('&'),
  '&lt;':ord('<'),
  '&gt;':ord('>'),
}

def string_to_ascii(s):
        if len(s) == 0:
                return -1
        if len(s) == 1:
                return ord(s)
        try:
                i = punctuation[s]
                return i
        except:
                pass
        return -1

def modname(modifier):
        if modifier & 4:
                return "AltGr"
        if modifier & 1:
                return "Shift"
        return "plain"

def handle_key(modifier, s, keyname, keyid):
        ascii = string_to_ascii(s)
        if ascii == -1:
                return
        if keys[ascii] != 0:
                # We already have an entry for this character
                # Keep the most accessible version
                # unshifted beats shifted beats altgr
                if modifier < modifiers[ascii]:
                        if keys[ascii] != keyid:
                                print "  Replacing ", chr(ascii), "on", modname(modifiers[ascii]), saved_keyname[ascii], "with", modname(modifier), keyname
                                keys[ascii] = keyid
                                saved_keyname[ascii] = keyname
                        modifiers[ascii] = modifier;
                else:
                        if keys[ascii] != keyid:
                                print "  Discarding", chr(ascii), "on", modname(modifier), keyname, "already have", modname(modifiers[ascii]), saved_keyname[ascii]
        else:
                # First time we've seen this character
                saved_keyname[ascii] = keyname
                keys[ascii] = keyid
                modifiers[ascii] = modifier

seenlines = {};

def collect_line(line):
        global seenlines
        try:
                s = split("\W+",sub("\t|{|}|\[|]|\,|&lt;|&gt;|;", " ", line))
        except:
                return

        if s[1] == 'key':
                seenlines[s[2]] = s[3:6]
        else:
                if s[0] == 'key':
                        seenlines[s[1]] = s[2:5]

def process_keys():
        global seenlines

        if len(seenlines) == 0:
                print "Didn't find any key definitions"
                raise ValueError
        for k in seenlines:
                try:
                        keyid = keynames[k]
                except:
                        print "Bad key name",k

                handle_key(0,seenlines[k][0], k, keyid) # Unshift
                handle_key(1,seenlines[k][1], k, keyid) # Shift
                handle_key(4,seenlines[k][2], k, keyid) # AltGr

# This table converts from the IBM physical keystation number to
# the corresponding scancode value in scan set 1.

def put_ka_format(outfile):
        global keys, modifiers
        # a-z - output scancode only; unshifted map is implied
        # and shifted map is derived automatically
        for i in range(ord('a'),ord('a')+26):
                if (keys[i] == 0):
                        print "Missing",chr(i)
                if modifiers[i] != 0:
                        print chr(i),"is modified"
                outfile.write(chr(keys[i]))

        # Numbers and punctuation - output scancode and keymap number
        for i in '0123456789!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~':
                ascii = ord(i)
                if (keys[ascii] == 0):
                        print "Missing",i
                if (modifiers[ascii] & 0xa) != 0:
                        print i,"is Ctrl or Fn"
                outfile.write(chr(keys[ascii]))
                
                if (modifiers[ascii] & 0x4) != 0:
                        # modifier & 4 implies AltGr map
                        outfile.write(chr(2))
                else:
                        # otherwise it's either the shift (1) or unshift (0) map
                        outfile.write(chr(modifiers[ascii] & 1))
        
        outfile.write(chr(0))   # Null terminator
        
        outfile.write(chr(111 ^ 0xff))
        outfile.write(chr(111))
        outfile.write('KA')

def wiki_to_ka(argv):
        try:
                try:
                        print  "Getting",'http://wiki.laptop.org/go/' + argv[1]
                        infile = urlopen('http://wiki.laptop.org/go/' + argv[1])
                except IOError:
                        print "Can't open that URL"
                for line in infile:
                        collect_line(line)
                infile.close()
                process_keys()
                try:
                        outfile = open(argv[1] + '.ka', 'w')
                except IOError:
                        print "Can't open output file",argv[1] + '.ka'
                        raise
                put_ka_format(outfile)
                outfile.close()
                print "Output at",argv[1] + '.ka'
        except:
                print "Failed"

if len(argv) != 2:
        print "Usage: python parsekbd.py PageName"
else:
        wiki_to_ka(argv)
