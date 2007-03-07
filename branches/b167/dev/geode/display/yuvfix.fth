\ See license at end of file
\ These mapping tables compensate for errors in the Geode's YUV to RGB transform.
\ AMD App note 31566A, May 2004

decimal

create red-gamma
  0 c,   4 c,   5 c,   6 c,   7 c,   8 c,   9 c,  10 c,  11 c,  12 c,  13 c,  14 c,  15 c,  16 c,  17 c,  17 c, 
 18 c,  20 c,  21 c,  22 c,  23 c,  24 c,  25 c,  26 c,  27 c,  28 c,  29 c,  29 c,  30 c,  32 c,  32 c,  34 c, 
 35 c,  36 c,  37 c,  38 c,  38 c,  40 c,  41 c,  41 c,  43 c,  44 c,  45 c,  46 c,  47 c,  48 c,  49 c,  50 c, 
 51 c,  52 c,  53 c,  54 c,  55 c,  56 c,  57 c,  58 c,  59 c,  60 c,  61 c,  62 c,  63 c,  64 c,  65 c,  66 c, 
 67 c,  68 c,  68 c,  69 c,  71 c,  72 c,  73 c,  74 c,  75 c,  76 c,  77 c,  78 c,  79 c,  80 c,  81 c,  82 c, 
 83 c,  84 c,  85 c,  86 c,  87 c,  88 c,  89 c,  90 c,  91 c,  92 c,  93 c,  94 c,  95 c,  96 c,  97 c,  98 c, 
 99 c, 100 c, 101 c, 102 c, 103 c, 104 c, 105 c, 106 c, 107 c, 108 c, 109 c, 110 c, 111 c, 112 c, 113 c, 114 c, 
115 c, 116 c, 117 c, 118 c, 119 c, 120 c, 121 c, 122 c, 123 c, 124 c, 125 c, 126 c, 127 c, 128 c, 129 c, 130 c, 
131 c, 132 c, 133 c, 134 c, 135 c, 136 c, 137 c, 138 c, 139 c, 140 c, 141 c, 142 c, 143 c, 144 c, 145 c, 146 c, 
147 c, 148 c, 149 c, 150 c, 151 c, 152 c, 153 c, 154 c, 155 c, 156 c, 157 c, 158 c, 159 c, 160 c, 161 c, 162 c, 
163 c, 164 c, 165 c, 166 c, 167 c, 168 c, 169 c, 170 c, 171 c, 172 c, 173 c, 174 c, 175 c, 176 c, 177 c, 178 c, 
179 c, 180 c, 181 c, 182 c, 183 c, 184 c, 185 c, 186 c, 187 c, 188 c, 189 c, 190 c, 191 c, 192 c, 193 c, 194 c, 
195 c, 196 c, 197 c, 198 c, 199 c, 200 c, 201 c, 202 c, 203 c, 204 c, 205 c, 206 c, 207 c, 208 c, 209 c, 210 c, 
211 c, 212 c, 213 c, 214 c, 215 c, 216 c, 217 c, 218 c, 219 c, 220 c, 221 c, 222 c, 223 c, 224 c, 225 c, 226 c, 
227 c, 228 c, 229 c, 230 c, 231 c, 232 c, 233 c, 234 c, 235 c, 236 c, 237 c, 238 c, 239 c, 240 c, 241 c, 242 c, 
243 c, 244 c, 245 c, 246 c, 247 c, 248 c, 249 c, 250 c, 251 c, 252 c, 253 c, 254 c, 255 c, 255 c, 255 c, 255 c,

create green-gamma
  0 c,   0 c,   1 c,   2 c,   3 c,   4 c,   5 c,   6 c,   7 c,   8 c,   9 c,  10 c,  11 c,  12 c,  13 c,  14 c, 
 15 c,  16 c,  17 c,  18 c,  19 c,  20 c,  21 c,  22 c,  23 c,  24 c,  25 c,  26 c,  27 c,  28 c,  29 c,  30 c, 
 31 c,  32 c,  33 c,  34 c,  35 c,  36 c,  37 c,  38 c,  39 c,  40 c,  41 c,  42 c,  43 c,  44 c,  45 c,  46 c, 
 47 c,  48 c,  49 c,  50 c,  51 c,  52 c,  53 c,  54 c,  55 c,  56 c,  57 c,  58 c,  59 c,  60 c,  61 c,  62 c, 
 63 c,  64 c,  65 c,  66 c,  67 c,  68 c,  69 c,  70 c,  71 c,  72 c,  73 c,  74 c,  75 c,  76 c,  77 c,  78 c, 
 79 c,  80 c,  81 c,  82 c,  83 c,  84 c,  85 c,  86 c,  87 c,  88 c,  89 c,  90 c,  91 c,  92 c,  93 c,  94 c, 
 95 c,  96 c,  97 c,  98 c,  99 c, 100 c, 101 c, 102 c, 103 c, 104 c, 105 c, 106 c, 107 c, 108 c, 109 c, 110 c, 
111 c, 112 c, 113 c, 114 c, 115 c, 116 c, 117 c, 118 c, 119 c, 120 c, 121 c, 122 c, 123 c, 124 c, 125 c, 126 c, 
127 c, 128 c, 129 c, 130 c, 131 c, 132 c, 133 c, 134 c, 135 c, 136 c, 137 c, 138 c, 139 c, 140 c, 141 c, 142 c, 
143 c, 144 c, 145 c, 146 c, 147 c, 148 c, 149 c, 150 c, 151 c, 152 c, 153 c, 154 c, 155 c, 156 c, 157 c, 158 c, 
159 c, 160 c, 161 c, 162 c, 163 c, 164 c, 165 c, 166 c, 167 c, 168 c, 169 c, 170 c, 171 c, 172 c, 173 c, 174 c, 
175 c, 176 c, 177 c, 178 c, 179 c, 180 c, 181 c, 182 c, 183 c, 184 c, 185 c, 186 c, 187 c, 188 c, 189 c, 190 c, 
191 c, 192 c, 193 c, 194 c, 195 c, 196 c, 197 c, 198 c, 199 c, 200 c, 201 c, 202 c, 203 c, 204 c, 205 c, 206 c, 
207 c, 208 c, 209 c, 210 c, 211 c, 212 c, 213 c, 214 c, 215 c, 216 c, 217 c, 218 c, 219 c, 220 c, 221 c, 222 c, 
223 c, 224 c, 225 c, 226 c, 227 c, 228 c, 229 c, 230 c, 231 c, 232 c, 233 c, 234 c, 235 c, 236 c, 237 c, 238 c, 
239 c, 240 c, 241 c, 242 c, 243 c, 244 c, 245 c, 246 c, 247 c, 248 c, 249 c, 250 c, 251 c, 252 c, 253 c, 255 c,

create blue-gamma

  0 c,   3 c,   4 c,   5 c,   6 c,   7 c,   8 c,   9 c,  10 c,  11 c,  12 c,  13 c,  14 c,  15 c,  16 c,  17 c, 
 18 c,  19 c,  20 c,  21 c,  22 c,  23 c,  24 c,  25 c,  26 c,  27 c,  28 c,  29 c,  30 c,  31 c,  32 c,  33 c, 
 34 c,  35 c,  36 c,  37 c,  38 c,  39 c,  40 c,  41 c,  42 c,  43 c,  44 c,  45 c,  46 c,  47 c,  48 c,  49 c, 
 50 c,  51 c,  52 c,  53 c,  54 c,  55 c,  56 c,  57 c,  58 c,  59 c,  60 c,  61 c,  62 c,  63 c,  64 c,  65 c, 
 66 c,  67 c,  68 c,  69 c,  70 c,  71 c,  72 c,  73 c,  74 c,  75 c,  76 c,  77 c,  78 c,  79 c,  80 c,  81 c, 
 82 c,  83 c,  84 c,  85 c,  86 c,  87 c,  88 c,  89 c,  90 c,  91 c,  92 c,  93 c,  94 c,  95 c,  96 c,  97 c, 
 98 c,  99 c, 100 c, 101 c, 102 c, 103 c, 104 c, 105 c, 106 c, 107 c, 108 c, 109 c, 110 c, 111 c, 112 c, 113 c, 
114 c, 115 c, 116 c, 117 c, 118 c, 119 c, 120 c, 121 c, 122 c, 123 c, 124 c, 125 c, 126 c, 127 c, 128 c, 129 c, 
130 c, 131 c, 132 c, 133 c, 134 c, 135 c, 136 c, 137 c, 138 c, 139 c, 140 c, 141 c, 142 c, 143 c, 144 c, 145 c, 
146 c, 147 c, 148 c, 149 c, 150 c, 151 c, 152 c, 153 c, 154 c, 155 c, 156 c, 157 c, 158 c, 159 c, 160 c, 161 c, 
162 c, 163 c, 164 c, 165 c, 166 c, 167 c, 168 c, 169 c, 170 c, 171 c, 172 c, 173 c, 174 c, 175 c, 176 c, 177 c, 
178 c, 179 c, 180 c, 181 c, 182 c, 183 c, 184 c, 185 c, 186 c, 187 c, 188 c, 189 c, 190 c, 191 c, 192 c, 193 c, 
194 c, 195 c, 196 c, 197 c, 198 c, 199 c, 200 c, 201 c, 202 c, 203 c, 204 c, 205 c, 206 c, 207 c, 208 c, 209 c, 
210 c, 211 c, 212 c, 213 c, 214 c, 215 c, 216 c, 217 c, 218 c, 219 c, 220 c, 221 c, 222 c, 223 c, 224 c, 225 c, 
226 c, 227 c, 228 c, 229 c, 230 c, 231 c, 232 c, 233 c, 234 c, 235 c, 236 c, 237 c, 238 c, 239 c, 240 c, 241 c, 
242 c, 243 c, 244 c, 245 c, 246 c, 247 c, 248 c, 249 c, 250 c, 251 c, 252 c, 253 c, 254 c, 254 c, 254 c, 255 c,

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
