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
from HTMLParser import HTMLParser

lastdata = ""
indent = 0
tableseen = False
keys = 128*[0]
modifiers = 128*[0]
column = 0
keyid = 0

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
        if (len(s) == 3) & (s[:2] == 'C-'):
                return ord(s[2]) & 0x1f
        return -1

def handle_key(modifier, s):
        global keyid
        ascii = string_to_ascii(s)
        if ascii == -1:
                return
        if keys[ascii] != 0:
                if (ascii >= 0x20) & (((modifier & 1) == 0) & (keys[ascii] != keyid)):
                        if modifier < modifiers[ascii]:
                                print "Replacing", chr(ascii), "at keyid", keys[ascii], "modifier", modifiers[ascii], "with keyid", keyid, "modifier", modifier
                                modifiers[ascii] = modifier
                                keys[ascii] = keyid
                        else:
                                print "Discarding", chr(ascii), "at keyid", keyid, "modifier", modifier, "because keyid", keys[ascii], "modifier", modifiers[ascii], "is better"
                        return
        if ascii < 0x20:
                if (modifier & 2) != 0:   # ctrl
                        if keys[ascii + 0x60] == keyid:
                                return
                        if keys[ascii + 0x40] == keyid:
                                return
        keys[ascii] = keyid
        modifiers[ascii] = modifier

def do_key():
        global column, keyid, lastdata
        s = lastdata.strip()
        if column == 1:    # row
                pass
        elif column == 2:  # Key
                if s.isdigit():
                        keyid = int(s)
        elif column == 3:  # Unmodified
                handle_key(0,s)
        elif column == 4:  # Shift
                handle_key(1,s)
        elif column == 5:  # AltGR
                handle_key(4,s)
        elif column == 6:  # Shift AltGr
                # handle_key(5,s)
                pass
        elif column == 7:  # Ctrl
                handle_key(2,s)
        elif column == 8:  # Ctrl Shift
                handle_key(6,s)
        elif column == 9:  # Fn
                handle_key(8,s)
        elif column == 10:  # comment
                pass
        elif column == 11:  # another comment
                pass

class MyHTMLParser(HTMLParser):
    def handle_starttag(self, tag, attrs):
        global column, keyid, indent, lastdata
        #for i in range(indent):
        #        print "",
        #print "<", tag
        #indent = indent+2
        if tag == 'tr':
                column = 0
                keyid = 0
        elif tag == 'td':
                lastdata = ""
                column = column + 1;
    
    def handle_endtag(self, tag):
        global tableseen, column, keyid, indent
        #for i in range(indent):
        #        print "",
        #print tag,">" 
        #indent = indent - 2
        #if indent < 0:
        #        indent = 0

        if tag == 'table':
                tableseen = True
        elif (tag == 'td') & tableseen:
                do_key()
    
    def handle_data(self, data):
        global lastdata, indent
        #for i in range(indent):
        #        print "",
        #print "{", data, "}"
        lastdata = lastdata + data.strip()
        if lastdata.startswith("There is currently no text"):
                print "No such Wiki page"
                raise

    def handle_entityref(self, data):
        global lastdata, indent
        #for i in range(indent):
        #        print "",
        #print "{", data, "}"
        # print "Entity", data.strip()
        lastdata = lastdata + "&" + data.strip() + ";"

# This table converts from the IBM physical keystation number to
# the corresponding scancode value in scan set 1.

#   0     1     3     3     4     5     6     7     8     9
scan1_map = [
 0x00, 0x29, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,    # 0x
 0x0a, 0x0b, 0x0c, 0x0d, 0x00, 0x0e, 0x0f, 0x10, 0x11, 0x12,    # 1x
 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x2b,    # 2x
 0x3a, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26,    # 3x
 0x27, 0x28, 0x2b, 0x1c, 0x2a, 0x56, 0x2c, 0x2d, 0x2e, 0x2f,    # 4x
 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x73, 0x36, 0x1d, 0x00,    # 5x
 0x38, 0x39, 0x38, 0x00, 0x1d, 0x00, 0x00, 0x00, 0x00, 0x00,    # 6x
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,    # 7x
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,    # 8x
 0x45, 0x47, 0x4B, 0x4F, 0x00, 0x00, 0x48, 0x4C, 0x50, 0x52,    # 9x
 0x37, 0x49, 0x4D, 0x51, 0x53, 0x4A, 0x4E, 0x00, 0x1c, 0x00,    # 10x 
 0x01, 0x00, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42,    # 11x
 0x43, 0x44, 0x57, 0x58, 0x00, 0x46, 0x00, 0x00, 0x00, 0x00,    # 12x
 0x79, 0x01, 0x00, 0x5c, 0x73, 0x6e, 0x00, 0x00, 0x00, 0x00,    # 13x (analog intermediates)
 0x00, 0x00, 0x00, 0x00, 0x00,                                  # 14x
]

def put_ka_format(outfile):
        global keys, modifiers
        # a-z - output scancode only; unshifted map is implied
        # and shifted map is derived automatically
        for i in range(ord('a'),ord('a')+26):
                if (keys[i] == 0):
                        print "Missing",chr(i)
                if modifiers[i] != 0:
                        print chr(i),"is modified"
                outfile.write(chr(scan1_map[keys[i]]))
        
        # Numbers and punctuation - output scancode and keymap number
        for i in '0123456789!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~':
                ascii = ord(i)
                if (keys[ascii] == 0):
                        print "Missing",i
                if (modifiers[ascii] & 0xa) != 0:
                        print i,"is Ctrl or Fn"
                outfile.write(chr(scan1_map[keys[ascii]]))
                
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

if len(argv) != 2:
        print "Usage: python parsekbd.py PageName"
else:
        try:
                print "Getting",'http://wiki.laptop.org/go/' + argv[1]
                infile = urlopen('http://wiki.laptop.org/go/' + argv[1])
                myparser=MyHTMLParser()
                myparser.feed(infile.read())
                myparser.close()
                infile.close()
                outfile = open(argv[1] + '.ka', 'w')
                put_ka_format(outfile)
                outfile.close()
                print "Output at",argv[1] + '.ka'
        except:
                print "Failed"
