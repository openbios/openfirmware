hex

\ =======================================================================
\ Data structures and constants
\
\ Te0[x] = S [x].[02, 01, 01, 03];
\ Te1[x] = S [x].[03, 02, 01, 01];
\ Te2[x] = S [x].[01, 03, 02, 01];
\ Te3[x] = S [x].[01, 01, 03, 02];
\
\ Td0[x] = Si[x].[0e, 09, 0d, 0b];
\ Td1[x] = Si[x].[0b, 0e, 09, 0d];
\ Td2[x] = Si[x].[0d, 0b, 0e, 09];
\ Td3[x] = Si[x].[09, 0d, 0b, 0e];
\ Td4[x] = Si[x].[01];

d# 15 4 * constant #rd-key
struct
  #rd-key 4 * field >rd-key
  4 field >rounds
constant /sk

create te0
   c66363a5 l,  f87c7c84 l,  ee777799 l,  f67b7b8d l,  
   fff2f20d l,  d66b6bbd l,  de6f6fb1 l,  91c5c554 l,  
   60303050 l,  02010103 l,  ce6767a9 l,  562b2b7d l,  
   e7fefe19 l,  b5d7d762 l,  4dababe6 l,  ec76769a l,  
   8fcaca45 l,  1f82829d l,  89c9c940 l,  fa7d7d87 l,  
   effafa15 l,  b25959eb l,  8e4747c9 l,  fbf0f00b l,  
   41adadec l,  b3d4d467 l,  5fa2a2fd l,  45afafea l,  
   239c9cbf l,  53a4a4f7 l,  e4727296 l,  9bc0c05b l,  
   75b7b7c2 l,  e1fdfd1c l,  3d9393ae l,  4c26266a l,  
   6c36365a l,  7e3f3f41 l,  f5f7f702 l,  83cccc4f l,  
   6834345c l,  51a5a5f4 l,  d1e5e534 l,  f9f1f108 l,  
   e2717193 l,  abd8d873 l,  62313153 l,  2a15153f l,  
   0804040c l,  95c7c752 l,  46232365 l,  9dc3c35e l,  
   30181828 l,  379696a1 l,  0a05050f l,  2f9a9ab5 l,  
   0e070709 l,  24121236 l,  1b80809b l,  dfe2e23d l,  
   cdebeb26 l,  4e272769 l,  7fb2b2cd l,  ea75759f l,  
   1209091b l,  1d83839e l,  582c2c74 l,  341a1a2e l,  
   361b1b2d l,  dc6e6eb2 l,  b45a5aee l,  5ba0a0fb l,  
   a45252f6 l,  763b3b4d l,  b7d6d661 l,  7db3b3ce l,  
   5229297b l,  dde3e33e l,  5e2f2f71 l,  13848497 l,  
   a65353f5 l,  b9d1d168 l,  00000000 l,  c1eded2c l,  
   40202060 l,  e3fcfc1f l,  79b1b1c8 l,  b65b5bed l,  
   d46a6abe l,  8dcbcb46 l,  67bebed9 l,  7239394b l,  
   944a4ade l,  984c4cd4 l,  b05858e8 l,  85cfcf4a l,  
   bbd0d06b l,  c5efef2a l,  4faaaae5 l,  edfbfb16 l,  
   864343c5 l,  9a4d4dd7 l,  66333355 l,  11858594 l,  
   8a4545cf l,  e9f9f910 l,  04020206 l,  fe7f7f81 l,  
   a05050f0 l,  783c3c44 l,  259f9fba l,  4ba8a8e3 l,  
   a25151f3 l,  5da3a3fe l,  804040c0 l,  058f8f8a l,  
   3f9292ad l,  219d9dbc l,  70383848 l,  f1f5f504 l,  
   63bcbcdf l,  77b6b6c1 l,  afdada75 l,  42212163 l,  
   20101030 l,  e5ffff1a l,  fdf3f30e l,  bfd2d26d l,  
   81cdcd4c l,  180c0c14 l,  26131335 l,  c3ecec2f l,  
   be5f5fe1 l,  359797a2 l,  884444cc l,  2e171739 l,  
   93c4c457 l,  55a7a7f2 l,  fc7e7e82 l,  7a3d3d47 l,  
   c86464ac l,  ba5d5de7 l,  3219192b l,  e6737395 l,  
   c06060a0 l,  19818198 l,  9e4f4fd1 l,  a3dcdc7f l,  
   44222266 l,  542a2a7e l,  3b9090ab l,  0b888883 l,  
   8c4646ca l,  c7eeee29 l,  6bb8b8d3 l,  2814143c l,  
   a7dede79 l,  bc5e5ee2 l,  160b0b1d l,  addbdb76 l,  
   dbe0e03b l,  64323256 l,  743a3a4e l,  140a0a1e l,  
   924949db l,  0c06060a l,  4824246c l,  b85c5ce4 l,  
   9fc2c25d l,  bdd3d36e l,  43acacef l,  c46262a6 l,  
   399191a8 l,  319595a4 l,  d3e4e437 l,  f279798b l,  
   d5e7e732 l,  8bc8c843 l,  6e373759 l,  da6d6db7 l,  
   018d8d8c l,  b1d5d564 l,  9c4e4ed2 l,  49a9a9e0 l,  
   d86c6cb4 l,  ac5656fa l,  f3f4f407 l,  cfeaea25 l,  
   ca6565af l,  f47a7a8e l,  47aeaee9 l,  10080818 l,  
   6fbabad5 l,  f0787888 l,  4a25256f l,  5c2e2e72 l,  
   381c1c24 l,  57a6a6f1 l,  73b4b4c7 l,  97c6c651 l,  
   cbe8e823 l,  a1dddd7c l,  e874749c l,  3e1f1f21 l,  
   964b4bdd l,  61bdbddc l,  0d8b8b86 l,  0f8a8a85 l,  
   e0707090 l,  7c3e3e42 l,  71b5b5c4 l,  cc6666aa l,  
   904848d8 l,  06030305 l,  f7f6f601 l,  1c0e0e12 l,  
   c26161a3 l,  6a35355f l,  ae5757f9 l,  69b9b9d0 l,  
   17868691 l,  99c1c158 l,  3a1d1d27 l,  279e9eb9 l,  
   d9e1e138 l,  ebf8f813 l,  2b9898b3 l,  22111133 l,  
   d26969bb l,  a9d9d970 l,  078e8e89 l,  339494a7 l,  
   2d9b9bb6 l,  3c1e1e22 l,  15878792 l,  c9e9e920 l,  
   87cece49 l,  aa5555ff l,  50282878 l,  a5dfdf7a l,  
   038c8c8f l,  59a1a1f8 l,  09898980 l,  1a0d0d17 l,  
   65bfbfda l,  d7e6e631 l,  844242c6 l,  d06868b8 l,  
   824141c3 l,  299999b0 l,  5a2d2d77 l,  1e0f0f11 l,  
   7bb0b0cb l,  a85454fc l,  6dbbbbd6 l,  2c16163a l,  

create te1
   a5c66363 l,  84f87c7c l,  99ee7777 l,  8df67b7b l,  
   0dfff2f2 l,  bdd66b6b l,  b1de6f6f l,  5491c5c5 l,  
   50603030 l,  03020101 l,  a9ce6767 l,  7d562b2b l,  
   19e7fefe l,  62b5d7d7 l,  e64dabab l,  9aec7676 l,  
   458fcaca l,  9d1f8282 l,  4089c9c9 l,  87fa7d7d l,  
   15effafa l,  ebb25959 l,  c98e4747 l,  0bfbf0f0 l,  
   ec41adad l,  67b3d4d4 l,  fd5fa2a2 l,  ea45afaf l,  
   bf239c9c l,  f753a4a4 l,  96e47272 l,  5b9bc0c0 l,  
   c275b7b7 l,  1ce1fdfd l,  ae3d9393 l,  6a4c2626 l,  
   5a6c3636 l,  417e3f3f l,  02f5f7f7 l,  4f83cccc l,  
   5c683434 l,  f451a5a5 l,  34d1e5e5 l,  08f9f1f1 l,  
   93e27171 l,  73abd8d8 l,  53623131 l,  3f2a1515 l,  
   0c080404 l,  5295c7c7 l,  65462323 l,  5e9dc3c3 l,  
   28301818 l,  a1379696 l,  0f0a0505 l,  b52f9a9a l,  
   090e0707 l,  36241212 l,  9b1b8080 l,  3ddfe2e2 l,  
   26cdebeb l,  694e2727 l,  cd7fb2b2 l,  9fea7575 l,  
   1b120909 l,  9e1d8383 l,  74582c2c l,  2e341a1a l,  
   2d361b1b l,  b2dc6e6e l,  eeb45a5a l,  fb5ba0a0 l,  
   f6a45252 l,  4d763b3b l,  61b7d6d6 l,  ce7db3b3 l,  
   7b522929 l,  3edde3e3 l,  715e2f2f l,  97138484 l,  
   f5a65353 l,  68b9d1d1 l,  00000000 l,  2cc1eded l,  
   60402020 l,  1fe3fcfc l,  c879b1b1 l,  edb65b5b l,  
   bed46a6a l,  468dcbcb l,  d967bebe l,  4b723939 l,  
   de944a4a l,  d4984c4c l,  e8b05858 l,  4a85cfcf l,  
   6bbbd0d0 l,  2ac5efef l,  e54faaaa l,  16edfbfb l,  
   c5864343 l,  d79a4d4d l,  55663333 l,  94118585 l,  
   cf8a4545 l,  10e9f9f9 l,  06040202 l,  81fe7f7f l,  
   f0a05050 l,  44783c3c l,  ba259f9f l,  e34ba8a8 l,  
   f3a25151 l,  fe5da3a3 l,  c0804040 l,  8a058f8f l,  
   ad3f9292 l,  bc219d9d l,  48703838 l,  04f1f5f5 l,  
   df63bcbc l,  c177b6b6 l,  75afdada l,  63422121 l,  
   30201010 l,  1ae5ffff l,  0efdf3f3 l,  6dbfd2d2 l,  
   4c81cdcd l,  14180c0c l,  35261313 l,  2fc3ecec l,  
   e1be5f5f l,  a2359797 l,  cc884444 l,  392e1717 l,  
   5793c4c4 l,  f255a7a7 l,  82fc7e7e l,  477a3d3d l,  
   acc86464 l,  e7ba5d5d l,  2b321919 l,  95e67373 l,  
   a0c06060 l,  98198181 l,  d19e4f4f l,  7fa3dcdc l,  
   66442222 l,  7e542a2a l,  ab3b9090 l,  830b8888 l,  
   ca8c4646 l,  29c7eeee l,  d36bb8b8 l,  3c281414 l,  
   79a7dede l,  e2bc5e5e l,  1d160b0b l,  76addbdb l,  
   3bdbe0e0 l,  56643232 l,  4e743a3a l,  1e140a0a l,  
   db924949 l,  0a0c0606 l,  6c482424 l,  e4b85c5c l,  
   5d9fc2c2 l,  6ebdd3d3 l,  ef43acac l,  a6c46262 l,  
   a8399191 l,  a4319595 l,  37d3e4e4 l,  8bf27979 l,  
   32d5e7e7 l,  438bc8c8 l,  596e3737 l,  b7da6d6d l,  
   8c018d8d l,  64b1d5d5 l,  d29c4e4e l,  e049a9a9 l,  
   b4d86c6c l,  faac5656 l,  07f3f4f4 l,  25cfeaea l,  
   afca6565 l,  8ef47a7a l,  e947aeae l,  18100808 l,  
   d56fbaba l,  88f07878 l,  6f4a2525 l,  725c2e2e l,  
   24381c1c l,  f157a6a6 l,  c773b4b4 l,  5197c6c6 l,  
   23cbe8e8 l,  7ca1dddd l,  9ce87474 l,  213e1f1f l,  
   dd964b4b l,  dc61bdbd l,  860d8b8b l,  850f8a8a l,  
   90e07070 l,  427c3e3e l,  c471b5b5 l,  aacc6666 l,  
   d8904848 l,  05060303 l,  01f7f6f6 l,  121c0e0e l,  
   a3c26161 l,  5f6a3535 l,  f9ae5757 l,  d069b9b9 l,  
   91178686 l,  5899c1c1 l,  273a1d1d l,  b9279e9e l,  
   38d9e1e1 l,  13ebf8f8 l,  b32b9898 l,  33221111 l,  
   bbd26969 l,  70a9d9d9 l,  89078e8e l,  a7339494 l,  
   b62d9b9b l,  223c1e1e l,  92158787 l,  20c9e9e9 l,  
   4987cece l,  ffaa5555 l,  78502828 l,  7aa5dfdf l,  
   8f038c8c l,  f859a1a1 l,  80098989 l,  171a0d0d l,  
   da65bfbf l,  31d7e6e6 l,  c6844242 l,  b8d06868 l,  
   c3824141 l,  b0299999 l,  775a2d2d l,  111e0f0f l,  
   cb7bb0b0 l,  fca85454 l,  d66dbbbb l,  3a2c1616 l,  

create te2
   63a5c663 l,  7c84f87c l,  7799ee77 l,  7b8df67b l,  
   f20dfff2 l,  6bbdd66b l,  6fb1de6f l,  c55491c5 l,  
   30506030 l,  01030201 l,  67a9ce67 l,  2b7d562b l,  
   fe19e7fe l,  d762b5d7 l,  abe64dab l,  769aec76 l,  
   ca458fca l,  829d1f82 l,  c94089c9 l,  7d87fa7d l,  
   fa15effa l,  59ebb259 l,  47c98e47 l,  f00bfbf0 l,  
   adec41ad l,  d467b3d4 l,  a2fd5fa2 l,  afea45af l,  
   9cbf239c l,  a4f753a4 l,  7296e472 l,  c05b9bc0 l,  
   b7c275b7 l,  fd1ce1fd l,  93ae3d93 l,  266a4c26 l,  
   365a6c36 l,  3f417e3f l,  f702f5f7 l,  cc4f83cc l,  
   345c6834 l,  a5f451a5 l,  e534d1e5 l,  f108f9f1 l,  
   7193e271 l,  d873abd8 l,  31536231 l,  153f2a15 l,  
   040c0804 l,  c75295c7 l,  23654623 l,  c35e9dc3 l,  
   18283018 l,  96a13796 l,  050f0a05 l,  9ab52f9a l,  
   07090e07 l,  12362412 l,  809b1b80 l,  e23ddfe2 l,  
   eb26cdeb l,  27694e27 l,  b2cd7fb2 l,  759fea75 l,  
   091b1209 l,  839e1d83 l,  2c74582c l,  1a2e341a l,  
   1b2d361b l,  6eb2dc6e l,  5aeeb45a l,  a0fb5ba0 l,  
   52f6a452 l,  3b4d763b l,  d661b7d6 l,  b3ce7db3 l,  
   297b5229 l,  e33edde3 l,  2f715e2f l,  84971384 l,  
   53f5a653 l,  d168b9d1 l,  00000000 l,  ed2cc1ed l,  
   20604020 l,  fc1fe3fc l,  b1c879b1 l,  5bedb65b l,  
   6abed46a l,  cb468dcb l,  bed967be l,  394b7239 l,  
   4ade944a l,  4cd4984c l,  58e8b058 l,  cf4a85cf l,  
   d06bbbd0 l,  ef2ac5ef l,  aae54faa l,  fb16edfb l,  
   43c58643 l,  4dd79a4d l,  33556633 l,  85941185 l,  
   45cf8a45 l,  f910e9f9 l,  02060402 l,  7f81fe7f l,  
   50f0a050 l,  3c44783c l,  9fba259f l,  a8e34ba8 l,  
   51f3a251 l,  a3fe5da3 l,  40c08040 l,  8f8a058f l,  
   92ad3f92 l,  9dbc219d l,  38487038 l,  f504f1f5 l,  
   bcdf63bc l,  b6c177b6 l,  da75afda l,  21634221 l,  
   10302010 l,  ff1ae5ff l,  f30efdf3 l,  d26dbfd2 l,  
   cd4c81cd l,  0c14180c l,  13352613 l,  ec2fc3ec l,  
   5fe1be5f l,  97a23597 l,  44cc8844 l,  17392e17 l,  
   c45793c4 l,  a7f255a7 l,  7e82fc7e l,  3d477a3d l,  
   64acc864 l,  5de7ba5d l,  192b3219 l,  7395e673 l,  
   60a0c060 l,  81981981 l,  4fd19e4f l,  dc7fa3dc l,  
   22664422 l,  2a7e542a l,  90ab3b90 l,  88830b88 l,  
   46ca8c46 l,  ee29c7ee l,  b8d36bb8 l,  143c2814 l,  
   de79a7de l,  5ee2bc5e l,  0b1d160b l,  db76addb l,  
   e03bdbe0 l,  32566432 l,  3a4e743a l,  0a1e140a l,  
   49db9249 l,  060a0c06 l,  246c4824 l,  5ce4b85c l,  
   c25d9fc2 l,  d36ebdd3 l,  acef43ac l,  62a6c462 l,  
   91a83991 l,  95a43195 l,  e437d3e4 l,  798bf279 l,  
   e732d5e7 l,  c8438bc8 l,  37596e37 l,  6db7da6d l,  
   8d8c018d l,  d564b1d5 l,  4ed29c4e l,  a9e049a9 l,  
   6cb4d86c l,  56faac56 l,  f407f3f4 l,  ea25cfea l,  
   65afca65 l,  7a8ef47a l,  aee947ae l,  08181008 l,  
   bad56fba l,  7888f078 l,  256f4a25 l,  2e725c2e l,  
   1c24381c l,  a6f157a6 l,  b4c773b4 l,  c65197c6 l,  
   e823cbe8 l,  dd7ca1dd l,  749ce874 l,  1f213e1f l,  
   4bdd964b l,  bddc61bd l,  8b860d8b l,  8a850f8a l,  
   7090e070 l,  3e427c3e l,  b5c471b5 l,  66aacc66 l,  
   48d89048 l,  03050603 l,  f601f7f6 l,  0e121c0e l,  
   61a3c261 l,  355f6a35 l,  57f9ae57 l,  b9d069b9 l,  
   86911786 l,  c15899c1 l,  1d273a1d l,  9eb9279e l,  
   e138d9e1 l,  f813ebf8 l,  98b32b98 l,  11332211 l,  
   69bbd269 l,  d970a9d9 l,  8e89078e l,  94a73394 l,  
   9bb62d9b l,  1e223c1e l,  87921587 l,  e920c9e9 l,  
   ce4987ce l,  55ffaa55 l,  28785028 l,  df7aa5df l,  
   8c8f038c l,  a1f859a1 l,  89800989 l,  0d171a0d l,  
   bfda65bf l,  e631d7e6 l,  42c68442 l,  68b8d068 l,  
   41c38241 l,  99b02999 l,  2d775a2d l,  0f111e0f l,  
   b0cb7bb0 l,  54fca854 l,  bbd66dbb l,  163a2c16 l,  

create te3
   6363a5c6 l,  7c7c84f8 l,  777799ee l,  7b7b8df6 l,  
   f2f20dff l,  6b6bbdd6 l,  6f6fb1de l,  c5c55491 l,  
   30305060 l,  01010302 l,  6767a9ce l,  2b2b7d56 l,  
   fefe19e7 l,  d7d762b5 l,  ababe64d l,  76769aec l,  
   caca458f l,  82829d1f l,  c9c94089 l,  7d7d87fa l,  
   fafa15ef l,  5959ebb2 l,  4747c98e l,  f0f00bfb l,  
   adadec41 l,  d4d467b3 l,  a2a2fd5f l,  afafea45 l,  
   9c9cbf23 l,  a4a4f753 l,  727296e4 l,  c0c05b9b l,  
   b7b7c275 l,  fdfd1ce1 l,  9393ae3d l,  26266a4c l,  
   36365a6c l,  3f3f417e l,  f7f702f5 l,  cccc4f83 l,  
   34345c68 l,  a5a5f451 l,  e5e534d1 l,  f1f108f9 l,  
   717193e2 l,  d8d873ab l,  31315362 l,  15153f2a l,  
   04040c08 l,  c7c75295 l,  23236546 l,  c3c35e9d l,  
   18182830 l,  9696a137 l,  05050f0a l,  9a9ab52f l,  
   0707090e l,  12123624 l,  80809b1b l,  e2e23ddf l,  
   ebeb26cd l,  2727694e l,  b2b2cd7f l,  75759fea l,  
   09091b12 l,  83839e1d l,  2c2c7458 l,  1a1a2e34 l,  
   1b1b2d36 l,  6e6eb2dc l,  5a5aeeb4 l,  a0a0fb5b l,  
   5252f6a4 l,  3b3b4d76 l,  d6d661b7 l,  b3b3ce7d l,  
   29297b52 l,  e3e33edd l,  2f2f715e l,  84849713 l,  
   5353f5a6 l,  d1d168b9 l,  00000000 l,  eded2cc1 l,  
   20206040 l,  fcfc1fe3 l,  b1b1c879 l,  5b5bedb6 l,  
   6a6abed4 l,  cbcb468d l,  bebed967 l,  39394b72 l,  
   4a4ade94 l,  4c4cd498 l,  5858e8b0 l,  cfcf4a85 l,  
   d0d06bbb l,  efef2ac5 l,  aaaae54f l,  fbfb16ed l,  
   4343c586 l,  4d4dd79a l,  33335566 l,  85859411 l,  
   4545cf8a l,  f9f910e9 l,  02020604 l,  7f7f81fe l,  
   5050f0a0 l,  3c3c4478 l,  9f9fba25 l,  a8a8e34b l,  
   5151f3a2 l,  a3a3fe5d l,  4040c080 l,  8f8f8a05 l,  
   9292ad3f l,  9d9dbc21 l,  38384870 l,  f5f504f1 l,  
   bcbcdf63 l,  b6b6c177 l,  dada75af l,  21216342 l,  
   10103020 l,  ffff1ae5 l,  f3f30efd l,  d2d26dbf l,  
   cdcd4c81 l,  0c0c1418 l,  13133526 l,  ecec2fc3 l,  
   5f5fe1be l,  9797a235 l,  4444cc88 l,  1717392e l,  
   c4c45793 l,  a7a7f255 l,  7e7e82fc l,  3d3d477a l,  
   6464acc8 l,  5d5de7ba l,  19192b32 l,  737395e6 l,  
   6060a0c0 l,  81819819 l,  4f4fd19e l,  dcdc7fa3 l,  
   22226644 l,  2a2a7e54 l,  9090ab3b l,  8888830b l,  
   4646ca8c l,  eeee29c7 l,  b8b8d36b l,  14143c28 l,  
   dede79a7 l,  5e5ee2bc l,  0b0b1d16 l,  dbdb76ad l,  
   e0e03bdb l,  32325664 l,  3a3a4e74 l,  0a0a1e14 l,  
   4949db92 l,  06060a0c l,  24246c48 l,  5c5ce4b8 l,  
   c2c25d9f l,  d3d36ebd l,  acacef43 l,  6262a6c4 l,  
   9191a839 l,  9595a431 l,  e4e437d3 l,  79798bf2 l,  
   e7e732d5 l,  c8c8438b l,  3737596e l,  6d6db7da l,  
   8d8d8c01 l,  d5d564b1 l,  4e4ed29c l,  a9a9e049 l,  
   6c6cb4d8 l,  5656faac l,  f4f407f3 l,  eaea25cf l,  
   6565afca l,  7a7a8ef4 l,  aeaee947 l,  08081810 l,  
   babad56f l,  787888f0 l,  25256f4a l,  2e2e725c l,  
   1c1c2438 l,  a6a6f157 l,  b4b4c773 l,  c6c65197 l,  
   e8e823cb l,  dddd7ca1 l,  74749ce8 l,  1f1f213e l,  
   4b4bdd96 l,  bdbddc61 l,  8b8b860d l,  8a8a850f l,  
   707090e0 l,  3e3e427c l,  b5b5c471 l,  6666aacc l,  
   4848d890 l,  03030506 l,  f6f601f7 l,  0e0e121c l,  
   6161a3c2 l,  35355f6a l,  5757f9ae l,  b9b9d069 l,  
   86869117 l,  c1c15899 l,  1d1d273a l,  9e9eb927 l,  
   e1e138d9 l,  f8f813eb l,  9898b32b l,  11113322 l,  
   6969bbd2 l,  d9d970a9 l,  8e8e8907 l,  9494a733 l,  
   9b9bb62d l,  1e1e223c l,  87879215 l,  e9e920c9 l,  
   cece4987 l,  5555ffaa l,  28287850 l,  dfdf7aa5 l,  
   8c8c8f03 l,  a1a1f859 l,  89898009 l,  0d0d171a l,  
   bfbfda65 l,  e6e631d7 l,  4242c684 l,  6868b8d0 l,  
   4141c382 l,  9999b029 l,  2d2d775a l,  0f0f111e l,  
   b0b0cb7b l,  5454fca8 l,  bbbbd66d l,  16163a2c l,  

create td0
   51f4a750 l,  7e416553 l,  1a17a4c3 l,  3a275e96 l,  
   3bab6bcb l,  1f9d45f1 l,  acfa58ab l,  4be30393 l,  
   2030fa55 l,  ad766df6 l,  88cc7691 l,  f5024c25 l,  
   4fe5d7fc l,  c52acbd7 l,  26354480 l,  b562a38f l,  
   deb15a49 l,  25ba1b67 l,  45ea0e98 l,  5dfec0e1 l,  
   c32f7502 l,  814cf012 l,  8d4697a3 l,  6bd3f9c6 l,  
   038f5fe7 l,  15929c95 l,  bf6d7aeb l,  955259da l,  
   d4be832d l,  587421d3 l,  49e06929 l,  8ec9c844 l,  
   75c2896a l,  f48e7978 l,  99583e6b l,  27b971dd l,  
   bee14fb6 l,  f088ad17 l,  c920ac66 l,  7dce3ab4 l,  
   63df4a18 l,  e51a3182 l,  97513360 l,  62537f45 l,  
   b16477e0 l,  bb6bae84 l,  fe81a01c l,  f9082b94 l,  
   70486858 l,  8f45fd19 l,  94de6c87 l,  527bf8b7 l,  
   ab73d323 l,  724b02e2 l,  e31f8f57 l,  6655ab2a l,  
   b2eb2807 l,  2fb5c203 l,  86c57b9a l,  d33708a5 l,  
   302887f2 l,  23bfa5b2 l,  02036aba l,  ed16825c l,  
   8acf1c2b l,  a779b492 l,  f307f2f0 l,  4e69e2a1 l,  
   65daf4cd l,  0605bed5 l,  d134621f l,  c4a6fe8a l,  
   342e539d l,  a2f355a0 l,  058ae132 l,  a4f6eb75 l,  
   0b83ec39 l,  4060efaa l,  5e719f06 l,  bd6e1051 l,  
   3e218af9 l,  96dd063d l,  dd3e05ae l,  4de6bd46 l,  
   91548db5 l,  71c45d05 l,  0406d46f l,  605015ff l,  
   1998fb24 l,  d6bde997 l,  894043cc l,  67d99e77 l,  
   b0e842bd l,  07898b88 l,  e7195b38 l,  79c8eedb l,  
   a17c0a47 l,  7c420fe9 l,  f8841ec9 l,  00000000 l,  
   09808683 l,  322bed48 l,  1e1170ac l,  6c5a724e l,  
   fd0efffb l,  0f853856 l,  3daed51e l,  362d3927 l,  
   0a0fd964 l,  685ca621 l,  9b5b54d1 l,  24362e3a l,  
   0c0a67b1 l,  9357e70f l,  b4ee96d2 l,  1b9b919e l,  
   80c0c54f l,  61dc20a2 l,  5a774b69 l,  1c121a16 l,  
   e293ba0a l,  c0a02ae5 l,  3c22e043 l,  121b171d l,  
   0e090d0b l,  f28bc7ad l,  2db6a8b9 l,  141ea9c8 l,  
   57f11985 l,  af75074c l,  ee99ddbb l,  a37f60fd l,  
   f701269f l,  5c72f5bc l,  44663bc5 l,  5bfb7e34 l,  
   8b432976 l,  cb23c6dc l,  b6edfc68 l,  b8e4f163 l,  
   d731dcca l,  42638510 l,  13972240 l,  84c61120 l,  
   854a247d l,  d2bb3df8 l,  aef93211 l,  c729a16d l,  
   1d9e2f4b l,  dcb230f3 l,  0d8652ec l,  77c1e3d0 l,  
   2bb3166c l,  a970b999 l,  119448fa l,  47e96422 l,  
   a8fc8cc4 l,  a0f03f1a l,  567d2cd8 l,  223390ef l,  
   87494ec7 l,  d938d1c1 l,  8ccaa2fe l,  98d40b36 l,  
   a6f581cf l,  a57ade28 l,  dab78e26 l,  3fadbfa4 l,  
   2c3a9de4 l,  5078920d l,  6a5fcc9b l,  547e4662 l,  
   f68d13c2 l,  90d8b8e8 l,  2e39f75e l,  82c3aff5 l,  
   9f5d80be l,  69d0937c l,  6fd52da9 l,  cf2512b3 l,  
   c8ac993b l,  10187da7 l,  e89c636e l,  db3bbb7b l,  
   cd267809 l,  6e5918f4 l,  ec9ab701 l,  834f9aa8 l,  
   e6956e65 l,  aaffe67e l,  21bccf08 l,  ef15e8e6 l,  
   bae79bd9 l,  4a6f36ce l,  ea9f09d4 l,  29b07cd6 l,  
   31a4b2af l,  2a3f2331 l,  c6a59430 l,  35a266c0 l,  
   744ebc37 l,  fc82caa6 l,  e090d0b0 l,  33a7d815 l,  
   f104984a l,  41ecdaf7 l,  7fcd500e l,  1791f62f l,  
   764dd68d l,  43efb04d l,  ccaa4d54 l,  e49604df l,  
   9ed1b5e3 l,  4c6a881b l,  c12c1fb8 l,  4665517f l,  
   9d5eea04 l,  018c355d l,  fa877473 l,  fb0b412e l,  
   b3671d5a l,  92dbd252 l,  e9105633 l,  6dd64713 l,  
   9ad7618c l,  37a10c7a l,  59f8148e l,  eb133c89 l,  
   cea927ee l,  b761c935 l,  e11ce5ed l,  7a47b13c l,  
   9cd2df59 l,  55f2733f l,  1814ce79 l,  73c737bf l,  
   53f7cdea l,  5ffdaa5b l,  df3d6f14 l,  7844db86 l,  
   caaff381 l,  b968c43e l,  3824342c l,  c2a3405f l,  
   161dc372 l,  bce2250c l,  283c498b l,  ff0d9541 l,  
   39a80171 l,  080cb3de l,  d8b4e49c l,  6456c190 l,  
   7bcb8461 l,  d532b670 l,  486c5c74 l,  d0b85742 l,  

create td1
   5051f4a7 l,  537e4165 l,  c31a17a4 l,  963a275e l,  
   cb3bab6b l,  f11f9d45 l,  abacfa58 l,  934be303 l,  
   552030fa l,  f6ad766d l,  9188cc76 l,  25f5024c l,  
   fc4fe5d7 l,  d7c52acb l,  80263544 l,  8fb562a3 l,  
   49deb15a l,  6725ba1b l,  9845ea0e l,  e15dfec0 l,  
   02c32f75 l,  12814cf0 l,  a38d4697 l,  c66bd3f9 l,  
   e7038f5f l,  9515929c l,  ebbf6d7a l,  da955259 l,  
   2dd4be83 l,  d3587421 l,  2949e069 l,  448ec9c8 l,  
   6a75c289 l,  78f48e79 l,  6b99583e l,  dd27b971 l,  
   b6bee14f l,  17f088ad l,  66c920ac l,  b47dce3a l,  
   1863df4a l,  82e51a31 l,  60975133 l,  4562537f l,  
   e0b16477 l,  84bb6bae l,  1cfe81a0 l,  94f9082b l,  
   58704868 l,  198f45fd l,  8794de6c l,  b7527bf8 l,  
   23ab73d3 l,  e2724b02 l,  57e31f8f l,  2a6655ab l,  
   07b2eb28 l,  032fb5c2 l,  9a86c57b l,  a5d33708 l,  
   f2302887 l,  b223bfa5 l,  ba02036a l,  5ced1682 l,  
   2b8acf1c l,  92a779b4 l,  f0f307f2 l,  a14e69e2 l,  
   cd65daf4 l,  d50605be l,  1fd13462 l,  8ac4a6fe l,  
   9d342e53 l,  a0a2f355 l,  32058ae1 l,  75a4f6eb l,  
   390b83ec l,  aa4060ef l,  065e719f l,  51bd6e10 l,  
   f93e218a l,  3d96dd06 l,  aedd3e05 l,  464de6bd l,  
   b591548d l,  0571c45d l,  6f0406d4 l,  ff605015 l,  
   241998fb l,  97d6bde9 l,  cc894043 l,  7767d99e l,  
   bdb0e842 l,  8807898b l,  38e7195b l,  db79c8ee l,  
   47a17c0a l,  e97c420f l,  c9f8841e l,  00000000 l,  
   83098086 l,  48322bed l,  ac1e1170 l,  4e6c5a72 l,  
   fbfd0eff l,  560f8538 l,  1e3daed5 l,  27362d39 l,  
   640a0fd9 l,  21685ca6 l,  d19b5b54 l,  3a24362e l,  
   b10c0a67 l,  0f9357e7 l,  d2b4ee96 l,  9e1b9b91 l,  
   4f80c0c5 l,  a261dc20 l,  695a774b l,  161c121a l,  
   0ae293ba l,  e5c0a02a l,  433c22e0 l,  1d121b17 l,  
   0b0e090d l,  adf28bc7 l,  b92db6a8 l,  c8141ea9 l,  
   8557f119 l,  4caf7507 l,  bbee99dd l,  fda37f60 l,  
   9ff70126 l,  bc5c72f5 l,  c544663b l,  345bfb7e l,  
   768b4329 l,  dccb23c6 l,  68b6edfc l,  63b8e4f1 l,  
   cad731dc l,  10426385 l,  40139722 l,  2084c611 l,  
   7d854a24 l,  f8d2bb3d l,  11aef932 l,  6dc729a1 l,  
   4b1d9e2f l,  f3dcb230 l,  ec0d8652 l,  d077c1e3 l,  
   6c2bb316 l,  99a970b9 l,  fa119448 l,  2247e964 l,  
   c4a8fc8c l,  1aa0f03f l,  d8567d2c l,  ef223390 l,  
   c787494e l,  c1d938d1 l,  fe8ccaa2 l,  3698d40b l,  
   cfa6f581 l,  28a57ade l,  26dab78e l,  a43fadbf l,  
   e42c3a9d l,  0d507892 l,  9b6a5fcc l,  62547e46 l,  
   c2f68d13 l,  e890d8b8 l,  5e2e39f7 l,  f582c3af l,  
   be9f5d80 l,  7c69d093 l,  a96fd52d l,  b3cf2512 l,  
   3bc8ac99 l,  a710187d l,  6ee89c63 l,  7bdb3bbb l,  
   09cd2678 l,  f46e5918 l,  01ec9ab7 l,  a8834f9a l,  
   65e6956e l,  7eaaffe6 l,  0821bccf l,  e6ef15e8 l,  
   d9bae79b l,  ce4a6f36 l,  d4ea9f09 l,  d629b07c l,  
   af31a4b2 l,  312a3f23 l,  30c6a594 l,  c035a266 l,  
   37744ebc l,  a6fc82ca l,  b0e090d0 l,  1533a7d8 l,  
   4af10498 l,  f741ecda l,  0e7fcd50 l,  2f1791f6 l,  
   8d764dd6 l,  4d43efb0 l,  54ccaa4d l,  dfe49604 l,  
   e39ed1b5 l,  1b4c6a88 l,  b8c12c1f l,  7f466551 l,  
   049d5eea l,  5d018c35 l,  73fa8774 l,  2efb0b41 l,  
   5ab3671d l,  5292dbd2 l,  33e91056 l,  136dd647 l,  
   8c9ad761 l,  7a37a10c l,  8e59f814 l,  89eb133c l,  
   eecea927 l,  35b761c9 l,  ede11ce5 l,  3c7a47b1 l,  
   599cd2df l,  3f55f273 l,  791814ce l,  bf73c737 l,  
   ea53f7cd l,  5b5ffdaa l,  14df3d6f l,  867844db l,  
   81caaff3 l,  3eb968c4 l,  2c382434 l,  5fc2a340 l,  
   72161dc3 l,  0cbce225 l,  8b283c49 l,  41ff0d95 l,  
   7139a801 l,  de080cb3 l,  9cd8b4e4 l,  906456c1 l,  
   617bcb84 l,  70d532b6 l,  74486c5c l,  42d0b857 l,  

create td2
   a75051f4 l,  65537e41 l,  a4c31a17 l,  5e963a27 l,  
   6bcb3bab l,  45f11f9d l,  58abacfa l,  03934be3 l,  
   fa552030 l,  6df6ad76 l,  769188cc l,  4c25f502 l,  
   d7fc4fe5 l,  cbd7c52a l,  44802635 l,  a38fb562 l,  
   5a49deb1 l,  1b6725ba l,  0e9845ea l,  c0e15dfe l,  
   7502c32f l,  f012814c l,  97a38d46 l,  f9c66bd3 l,  
   5fe7038f l,  9c951592 l,  7aebbf6d l,  59da9552 l,  
   832dd4be l,  21d35874 l,  692949e0 l,  c8448ec9 l,  
   896a75c2 l,  7978f48e l,  3e6b9958 l,  71dd27b9 l,  
   4fb6bee1 l,  ad17f088 l,  ac66c920 l,  3ab47dce l,  
   4a1863df l,  3182e51a l,  33609751 l,  7f456253 l,  
   77e0b164 l,  ae84bb6b l,  a01cfe81 l,  2b94f908 l,  
   68587048 l,  fd198f45 l,  6c8794de l,  f8b7527b l,  
   d323ab73 l,  02e2724b l,  8f57e31f l,  ab2a6655 l,  
   2807b2eb l,  c2032fb5 l,  7b9a86c5 l,  08a5d337 l,  
   87f23028 l,  a5b223bf l,  6aba0203 l,  825ced16 l,  
   1c2b8acf l,  b492a779 l,  f2f0f307 l,  e2a14e69 l,  
   f4cd65da l,  bed50605 l,  621fd134 l,  fe8ac4a6 l,  
   539d342e l,  55a0a2f3 l,  e132058a l,  eb75a4f6 l,  
   ec390b83 l,  efaa4060 l,  9f065e71 l,  1051bd6e l,  
   8af93e21 l,  063d96dd l,  05aedd3e l,  bd464de6 l,  
   8db59154 l,  5d0571c4 l,  d46f0406 l,  15ff6050 l,  
   fb241998 l,  e997d6bd l,  43cc8940 l,  9e7767d9 l,  
   42bdb0e8 l,  8b880789 l,  5b38e719 l,  eedb79c8 l,  
   0a47a17c l,  0fe97c42 l,  1ec9f884 l,  00000000 l,  
   86830980 l,  ed48322b l,  70ac1e11 l,  724e6c5a l,  
   fffbfd0e l,  38560f85 l,  d51e3dae l,  3927362d l,  
   d9640a0f l,  a621685c l,  54d19b5b l,  2e3a2436 l,  
   67b10c0a l,  e70f9357 l,  96d2b4ee l,  919e1b9b l,  
   c54f80c0 l,  20a261dc l,  4b695a77 l,  1a161c12 l,  
   ba0ae293 l,  2ae5c0a0 l,  e0433c22 l,  171d121b l,  
   0d0b0e09 l,  c7adf28b l,  a8b92db6 l,  a9c8141e l,  
   198557f1 l,  074caf75 l,  ddbbee99 l,  60fda37f l,  
   269ff701 l,  f5bc5c72 l,  3bc54466 l,  7e345bfb l,  
   29768b43 l,  c6dccb23 l,  fc68b6ed l,  f163b8e4 l,  
   dccad731 l,  85104263 l,  22401397 l,  112084c6 l,  
   247d854a l,  3df8d2bb l,  3211aef9 l,  a16dc729 l,  
   2f4b1d9e l,  30f3dcb2 l,  52ec0d86 l,  e3d077c1 l,  
   166c2bb3 l,  b999a970 l,  48fa1194 l,  642247e9 l,  
   8cc4a8fc l,  3f1aa0f0 l,  2cd8567d l,  90ef2233 l,  
   4ec78749 l,  d1c1d938 l,  a2fe8cca l,  0b3698d4 l,  
   81cfa6f5 l,  de28a57a l,  8e26dab7 l,  bfa43fad l,  
   9de42c3a l,  920d5078 l,  cc9b6a5f l,  4662547e l,  
   13c2f68d l,  b8e890d8 l,  f75e2e39 l,  aff582c3 l,  
   80be9f5d l,  937c69d0 l,  2da96fd5 l,  12b3cf25 l,  
   993bc8ac l,  7da71018 l,  636ee89c l,  bb7bdb3b l,  
   7809cd26 l,  18f46e59 l,  b701ec9a l,  9aa8834f l,  
   6e65e695 l,  e67eaaff l,  cf0821bc l,  e8e6ef15 l,  
   9bd9bae7 l,  36ce4a6f l,  09d4ea9f l,  7cd629b0 l,  
   b2af31a4 l,  23312a3f l,  9430c6a5 l,  66c035a2 l,  
   bc37744e l,  caa6fc82 l,  d0b0e090 l,  d81533a7 l,  
   984af104 l,  daf741ec l,  500e7fcd l,  f62f1791 l,  
   d68d764d l,  b04d43ef l,  4d54ccaa l,  04dfe496 l,  
   b5e39ed1 l,  881b4c6a l,  1fb8c12c l,  517f4665 l,  
   ea049d5e l,  355d018c l,  7473fa87 l,  412efb0b l,  
   1d5ab367 l,  d25292db l,  5633e910 l,  47136dd6 l,  
   618c9ad7 l,  0c7a37a1 l,  148e59f8 l,  3c89eb13 l,  
   27eecea9 l,  c935b761 l,  e5ede11c l,  b13c7a47 l,  
   df599cd2 l,  733f55f2 l,  ce791814 l,  37bf73c7 l,  
   cdea53f7 l,  aa5b5ffd l,  6f14df3d l,  db867844 l,  
   f381caaf l,  c43eb968 l,  342c3824 l,  405fc2a3 l,  
   c372161d l,  250cbce2 l,  498b283c l,  9541ff0d l,  
   017139a8 l,  b3de080c l,  e49cd8b4 l,  c1906456 l,  
   84617bcb l,  b670d532 l,  5c74486c l,  5742d0b8 l,  

create td3
   f4a75051 l,  4165537e l,  17a4c31a l,  275e963a l,  
   ab6bcb3b l,  9d45f11f l,  fa58abac l,  e303934b l,  
   30fa5520 l,  766df6ad l,  cc769188 l,  024c25f5 l,  
   e5d7fc4f l,  2acbd7c5 l,  35448026 l,  62a38fb5 l,  
   b15a49de l,  ba1b6725 l,  ea0e9845 l,  fec0e15d l,  
   2f7502c3 l,  4cf01281 l,  4697a38d l,  d3f9c66b l,  
   8f5fe703 l,  929c9515 l,  6d7aebbf l,  5259da95 l,  
   be832dd4 l,  7421d358 l,  e0692949 l,  c9c8448e l,  
   c2896a75 l,  8e7978f4 l,  583e6b99 l,  b971dd27 l,  
   e14fb6be l,  88ad17f0 l,  20ac66c9 l,  ce3ab47d l,  
   df4a1863 l,  1a3182e5 l,  51336097 l,  537f4562 l,  
   6477e0b1 l,  6bae84bb l,  81a01cfe l,  082b94f9 l,  
   48685870 l,  45fd198f l,  de6c8794 l,  7bf8b752 l,  
   73d323ab l,  4b02e272 l,  1f8f57e3 l,  55ab2a66 l,  
   eb2807b2 l,  b5c2032f l,  c57b9a86 l,  3708a5d3 l,  
   2887f230 l,  bfa5b223 l,  036aba02 l,  16825ced l,  
   cf1c2b8a l,  79b492a7 l,  07f2f0f3 l,  69e2a14e l,  
   daf4cd65 l,  05bed506 l,  34621fd1 l,  a6fe8ac4 l,  
   2e539d34 l,  f355a0a2 l,  8ae13205 l,  f6eb75a4 l,  
   83ec390b l,  60efaa40 l,  719f065e l,  6e1051bd l,  
   218af93e l,  dd063d96 l,  3e05aedd l,  e6bd464d l,  
   548db591 l,  c45d0571 l,  06d46f04 l,  5015ff60 l,  
   98fb2419 l,  bde997d6 l,  4043cc89 l,  d99e7767 l,  
   e842bdb0 l,  898b8807 l,  195b38e7 l,  c8eedb79 l,  
   7c0a47a1 l,  420fe97c l,  841ec9f8 l,  00000000 l,  
   80868309 l,  2bed4832 l,  1170ac1e l,  5a724e6c l,  
   0efffbfd l,  8538560f l,  aed51e3d l,  2d392736 l,  
   0fd9640a l,  5ca62168 l,  5b54d19b l,  362e3a24 l,  
   0a67b10c l,  57e70f93 l,  ee96d2b4 l,  9b919e1b l,  
   c0c54f80 l,  dc20a261 l,  774b695a l,  121a161c l,  
   93ba0ae2 l,  a02ae5c0 l,  22e0433c l,  1b171d12 l,  
   090d0b0e l,  8bc7adf2 l,  b6a8b92d l,  1ea9c814 l,  
   f1198557 l,  75074caf l,  99ddbbee l,  7f60fda3 l,  
   01269ff7 l,  72f5bc5c l,  663bc544 l,  fb7e345b l,  
   4329768b l,  23c6dccb l,  edfc68b6 l,  e4f163b8 l,  
   31dccad7 l,  63851042 l,  97224013 l,  c6112084 l,  
   4a247d85 l,  bb3df8d2 l,  f93211ae l,  29a16dc7 l,  
   9e2f4b1d l,  b230f3dc l,  8652ec0d l,  c1e3d077 l,  
   b3166c2b l,  70b999a9 l,  9448fa11 l,  e9642247 l,  
   fc8cc4a8 l,  f03f1aa0 l,  7d2cd856 l,  3390ef22 l,  
   494ec787 l,  38d1c1d9 l,  caa2fe8c l,  d40b3698 l,  
   f581cfa6 l,  7ade28a5 l,  b78e26da l,  adbfa43f l,  
   3a9de42c l,  78920d50 l,  5fcc9b6a l,  7e466254 l,  
   8d13c2f6 l,  d8b8e890 l,  39f75e2e l,  c3aff582 l,  
   5d80be9f l,  d0937c69 l,  d52da96f l,  2512b3cf l,  
   ac993bc8 l,  187da710 l,  9c636ee8 l,  3bbb7bdb l,  
   267809cd l,  5918f46e l,  9ab701ec l,  4f9aa883 l,  
   956e65e6 l,  ffe67eaa l,  bccf0821 l,  15e8e6ef l,  
   e79bd9ba l,  6f36ce4a l,  9f09d4ea l,  b07cd629 l,  
   a4b2af31 l,  3f23312a l,  a59430c6 l,  a266c035 l,  
   4ebc3774 l,  82caa6fc l,  90d0b0e0 l,  a7d81533 l,  
   04984af1 l,  ecdaf741 l,  cd500e7f l,  91f62f17 l,  
   4dd68d76 l,  efb04d43 l,  aa4d54cc l,  9604dfe4 l,  
   d1b5e39e l,  6a881b4c l,  2c1fb8c1 l,  65517f46 l,  
   5eea049d l,  8c355d01 l,  877473fa l,  0b412efb l,  
   671d5ab3 l,  dbd25292 l,  105633e9 l,  d647136d l,  
   d7618c9a l,  a10c7a37 l,  f8148e59 l,  133c89eb l,  
   a927eece l,  61c935b7 l,  1ce5ede1 l,  47b13c7a l,  
   d2df599c l,  f2733f55 l,  14ce7918 l,  c737bf73 l,  
   f7cdea53 l,  fdaa5b5f l,  3d6f14df l,  44db8678 l,  
   aff381ca l,  68c43eb9 l,  24342c38 l,  a3405fc2 l,  
   1dc37216 l,  e2250cbc l,  3c498b28 l,  0d9541ff l,  
   a8017139 l,  0cb3de08 l,  b4e49cd8 l,  56c19064 l,  
   cb84617b l,  32b670d5 l,  6c5c7448 l,  b85742d0 l,  

create td4
   52 c,  09 c,  6a c,  d5 c,  30 c,  36 c,  a5 c,  38 c,  
   bf c,  40 c,  a3 c,  9e c,  81 c,  f3 c,  d7 c,  fb c,  
   7c c,  e3 c,  39 c,  82 c,  9b c,  2f c,  ff c,  87 c,  
   34 c,  8e c,  43 c,  44 c,  c4 c,  de c,  e9 c,  cb c,  
   54 c,  7b c,  94 c,  32 c,  a6 c,  c2 c,  23 c,  3d c,  
   ee c,  4c c,  95 c,  0b c,  42 c,  fa c,  c3 c,  4e c,  
   08 c,  2e c,  a1 c,  66 c,  28 c,  d9 c,  24 c,  b2 c,  
   76 c,  5b c,  a2 c,  49 c,  6d c,  8b c,  d1 c,  25 c,  
   72 c,  f8 c,  f6 c,  64 c,  86 c,  68 c,  98 c,  16 c,  
   d4 c,  a4 c,  5c c,  cc c,  5d c,  65 c,  b6 c,  92 c,  
   6c c,  70 c,  48 c,  50 c,  fd c,  ed c,  b9 c,  da c,  
   5e c,  15 c,  46 c,  57 c,  a7 c,  8d c,  9d c,  84 c,  
   90 c,  d8 c,  ab c,  00 c,  8c c,  bc c,  d3 c,  0a c,  
   f7 c,  e4 c,  58 c,  05 c,  b8 c,  b3 c,  45 c,  06 c,  
   d0 c,  2c c,  1e c,  8f c,  ca c,  3f c,  0f c,  02 c,  
   c1 c,  af c,  bd c,  03 c,  01 c,  13 c,  8a c,  6b c,  
   3a c,  91 c,  11 c,  41 c,  4f c,  67 c,  dc c,  ea c,  
   97 c,  f2 c,  cf c,  ce c,  f0 c,  b4 c,  e6 c,  73 c,  
   96 c,  ac c,  74 c,  22 c,  e7 c,  ad c,  35 c,  85 c,  
   e2 c,  f9 c,  37 c,  e8 c,  1c c,  75 c,  df c,  6e c,  
   47 c,  f1 c,  1a c,  71 c,  1d c,  29 c,  c5 c,  89 c,  
   6f c,  b7 c,  62 c,  0e c,  aa c,  18 c,  be c,  1b c,  
   fc c,  56 c,  3e c,  4b c,  c6 c,  d2 c,  79 c,  20 c,  
   9a c,  db c,  c0 c,  fe c,  78 c,  cd c,  5a c,  f4 c,  
   1f c,  dd c,  a8 c,  33 c,  88 c,  07 c,  c7 c,  31 c,  
   b1 c,  12 c,  10 c,  59 c,  27 c,  80 c,  ec c,  5f c,  
   60 c,  51 c,  7f c,  a9 c,  19 c,  b5 c,  4a c,  0d c,  
   2d c,  e5 c,  7a c,  9f c,  93 c,  c9 c,  9c c,  ef c,  
   a0 c,  e0 c,  3b c,  4d c,  ae c,  2a c,  f5 c,  b0 c,  
   c8 c,  eb c,  bb c,  3c c,  83 c,  53 c,  99 c,  61 c,  
   17 c,  2b c,  04 c,  7e c,  ba c,  77 c,  d6 c,  26 c,  
   e1 c,  69 c,  14 c,  63 c,  55 c,  21 c,  0c c,  7d c,  

\ For 128-bit blocks, Rijndael never uses more than 10 rcon values
create rcon
   01000000 l,  02000000 l,  04000000 l,  08000000 l,
   10000000 l,  20000000 l,  40000000 l,  80000000 l,
   1B000000 l,  36000000 l, 

: idx>offset  ( idx -- offset )  ff and 4 *  ;
: te0@  ( idx -- n )  idx>offset te0 + l@  ;
: te1@  ( idx -- n )  idx>offset te1 + l@  ;
: te2@  ( idx -- n )  idx>offset te2 + l@  ;
: te3@  ( idx -- n )  idx>offset te3 + l@  ;

: td0@  ( idx -- n )  idx>offset td0 + l@  ;
: td1@  ( idx -- n )  idx>offset td1 + l@  ;
: td2@  ( idx -- n )  idx>offset td2 + l@  ;
: td3@  ( idx -- n )  idx>offset td3 + l@  ;
: td4@  ( idx -- n )  ff and td4 + c@  ;

: rcon@  ( idx -- n )  idx>offset rcon + l@  ;

\ XXX For 64-bit machines, aes! and aes@ differ
: aes@  ( adr -- n )  be-l@  ;
: aes!  ( n adr -- )  be-l!  ;

\ =======================================================================
\ Expand the cipher key into the encryption key schedule.

0 value rk
0 value tk
0 value uk

: rk@  ( idx -- n )  4 * rk + l@  ;
: rk!  ( n idx -- )  4 * rk + l!  ;

: aes-set-encrypt-key-128  ( -- )
   d# 10 0  do
      3 rk@ >r
      0 rk@
      r@ d# 16 >> te2@ ff00.0000 and xor
      r@     8 >> te3@ 00ff.0000 and xor
      r@          te0@ 0000.ff00 and xor
      r> d# 24 >> te1@ 0000.00ff and xor
      i rcon@ xor 4 rk!
      1 rk@ 4 rk@ xor 5 rk!
      2 rk@ 5 rk@ xor 6 rk!
      3 rk@ 6 rk@ xor 7 rk!
      rk d# 16 + to rk
   loop
;

: aes-set-encrypt-key-192  ( -- )
   8 0  do
      5 rk@ >r
      0 rk@
      r@ d# 16 >> te2@ ff00.0000 and xor
      r@     8 >> te3@ 00ff.0000 and xor
      r@          te0@ 0000.ff00 and xor
      r> d# 24 >> te1@ 0000.00ff and xor
      i rcon@ xor 6 rk!
      1 rk@ 6 rk@ xor 7 rk!
      2 rk@ 7 rk@ xor 8 rk!
      3 rk@ 8 rk@ xor 9 rk!
      i 7 =  if  leave  then
      4 rk@     9 rk@ xor d# 10 rk!
      5 rk@ d# 10 rk@ xor d# 11 rk!
      rk d# 24 + to rk
   loop
;

: aes-set-encrypt-key-256  ( -- )
   7 0  do
      7 rk@ >r
      0 rk@
      r@ d# 16 >> te2@ ff00.0000 and xor
      r@     8 >> te3@ 00ff.0000 and xor
      r@          te0@ 0000.ff00 and xor
      r> d# 24 >> te1@ 0000.00ff and xor
      i rcon@ xor 8 rk!
      1 rk@     8 rk@ xor     9 rk!
      2 rk@     9 rk@ xor d# 10 rk!
      3 rk@ d# 10 rk@ xor d# 11 rk!
      i 6 =  if  leave  then
      d# 11 rk@ >r
      4 rk@
      r@ d# 24 >> te2@ ff00.0000 and xor
      r@ d# 16 >> te3@ 00ff.0000 and xor
      r@     8 >> te0@ 0000.ff00 and xor
      r>          te1@ 0000.00ff and xor
      d# 12 rk!
      5 rk@ d# 12 rk@ xor d# 13 rk!
      6 rk@ d# 13 rk@ xor d# 14 rk!
      7 rk@ d# 14 rk@ xor d# 15 rk!
      rk d# 32 + to rk
   loop
;

: aes-set-encrypt-key  ( userkey bits key -- )
   rot to uk
   ( key ) dup >rd-key to rk
   over case
      d# 128  of  d# 10  endof
      d# 192  of  d# 12  endof
      ( default )  d# 14 swap
   endcase
   swap >rounds l!

   4 0  do  uk i 4 * + aes@  i rk!  loop
   ( bits ) dup d# 128 =  if  drop aes-set-encrypt-key-128 exit  then

   uk d# 16 + aes@ 4 rk!
   uk d# 20 + aes@ 5 rk!
   ( bits ) dup d# 192 =  if  drop aes-set-encrypt-key-192 exit  then

   uk d# 24 + aes@ 6 rk!
   uk d# 28 + aes@ 7 rk!
   ( bits ) d# 256 =  if  aes-set-encrypt-key-256  then
;

\ =======================================================================
\ Expand the cipher key into the decryption key schedule.

: rk-xform  ( idx -- )
   dup  rk@
   dup  d# 24 >> te1@ td0@
   over d# 16 >> te1@ td1@ xor
   over     8 >> te1@ td2@ xor
   swap          te1@ td3@ xor
   swap rk!
;

: aes-set-decrypt-key  ( userkey bits key -- )
   dup >r aes-set-encrypt-key		( R: key )

   r@ >rd-key to rk

   \ Invert the order of the round keys
   0 r@ >rounds l@ 4 *  begin  2dup <  while
      over     rk@  over     rk@ 3 pick     rk!  over     rk!
      over 1+  rk@  over 1+  rk@ 3 pick 1+  rk!  over 1+  rk!
      over 2 + rk@  over 2 + rk@ 3 pick 2 + rk!  over 2 + rk!
      over 3 + rk@  over 3 + rk@ 3 pick 3 + rk!  over 3 + rk!
      4 - swap 4 + swap
   repeat  2drop

   \ Apply the invert MixColumn transform to all round keys but the first and the last
   r> >rounds l@ 1  do
      rk d# 16 + to rk
      4 0  do  i rk-xform  loop
   loop
;

\ =======================================================================
\ Decrypt a single block.  Crypt and plain can overlay.

0 value s0
0 value s1
0 value s2
0 value s3
0 value t0
0 value t1
0 value t2
0 value t3

: aes-decrypt  ( crypt plain key -- )
   dup >rd-key to rk
   rot					( plain key crypt )

   \ Map byte array block to cipher state and add initial round key
   dup         aes@ 0 rk@ xor to s0
   dup     4 + aes@ 1 rk@ xor to s1
   dup     8 + aes@ 2 rk@ xor to s2
       d# 12 + aes@ 3 rk@ xor to s3	( plain key )

   \ ((key->rounds >> 1) - 1) full rounds
   ( key ) >rounds l@ 1 >> dup 0  ?do	( plain rounds )
      s0 d# 24 >> td0@
      s3 d# 16 >> td1@ xor
      s2     8 >> td2@ xor
      s1          td3@ xor  4 rk@ xor  to t0
      s1 d# 24 >> td0@
      s0 d# 16 >> td1@ xor
      s3     8 >> td2@ xor
      s2          td3@ xor  5 rk@ xor  to t1
      s2 d# 24 >> td0@
      s1 d# 16 >> td1@ xor
      s0     8 >> td2@ xor
      s3          td3@ xor  6 rk@ xor  to t2
      s3 d# 24 >> td0@
      s2 d# 16 >> td1@ xor
      s1     8 >> td2@ xor
      s0          td3@ xor  7 rk@ xor  to t3
      rk d# 32 + to rk
      dup 1- i =  if  leave  then
      t0 d# 24 >> td0@
      t3 d# 16 >> td1@ xor
      t2     8 >> td2@ xor
      t1          td3@ xor  0 rk@ xor  to s0
      t1 d# 24 >> td0@
      t0 d# 16 >> td1@ xor
      t3     8 >> td2@ xor
      t2          td3@ xor  1 rk@ xor  to s1
      t2 d# 24 >> td0@
      t1 d# 16 >> td1@ xor
      t0     8 >> td2@ xor
      t3          td3@ xor  2 rk@ xor  to s2
      t3 d# 24 >> td0@
      t2 d# 16 >> td1@ xor
      t1     8 >> td2@ xor
      t0          td3@ xor  3 rk@ xor  to s3 
   loop  drop				( plain )

   \ Apply last round and map cipher state to byte array block
   t1 td4@  t2 8 >> td4@  t3 d# 16 >> td4@  t0 d# 24 >> td4@  bljoin
   0 rk@ xor  over aes!

   t2 td4@  t3 8 >> td4@  t0 d# 16 >> td4@  t1 d# 24 >> td4@  bljoin
   1 rk@ xor  over 4 + aes!

   t3 td4@  t0 8 >> td4@  t1 d# 16 >> td4@  t2 d# 24 >> td4@  bljoin
   2 rk@ xor  over 8 + aes!

   t0 td4@  t1 8 >> td4@  t2 d# 16 >> td4@  t3 d# 24 >> td4@  bljoin
   3 rk@ xor  swap d# 12 + aes!
;


\ =======================================================================
\ Unwrap key with AES Key Wrap Algorithm (128-bit KEK) (RFC3394)

0 value plain			\ Plaintext key, sn*64 bits
0 value sr			\ Pointer into plain
0 value sn			\ Len of the wrapped key in 64-bit units
8 buffer: sa
d# 16 buffer: sb

/sk buffer: sk

\ cipher is the wrapped key to be unwrapped
: aes-unwrap  ( kek cipher$ plain -- ok? )
   to plain  8 / to sn			( kek cipher )

   \ Initialize 0 variabless
   ( cipher ) dup sa 8 move
   ( cipher ) 8 + plain sn 8 * move
   sk /sk erase
   ( kek ) d# 16 8 * sk aes-set-decrypt-key

   \ Compute intermediate values
   \ For j = 5 to 0
   \    For i = n to 1
   \        B = AES-1(K, (A ^ t) | R[i]) where t = n*j+i
   \        A = MSB(64, B)
   \        R[i] = LSB(64, B)
   6 0  do
      plain sn 1- 8 * + to sr
      sn 0  ?do
         sa sb 8 move
         sn 5 j - * sn i - + sb 7 + c@ xor sb 7 + c!
         sr sb 8 + 8 move
         sb sb sk aes-decrypt
         sb sa 8 move
         sb 8 + sr 8 move
         sr 8 - to sr
      loop
   loop

   \ Output results.  These are already in plain.  Just verify that the
   \ IV matches with the expected value.
   sa l@ h# a6a6.a6a6 =  sa 4 + l@ h# a6a6.a6a6 = and
;



0 [if]

\ Test case:

create kek   00 c, 01 c, 02 c, 03 c, 04 c, 05 c, 06 c, 07 c,
             08 c, 09 c, 0a c, 0b c, 0c c, 0d c, 0e c, 0f c,
create crypt 1f c, a6 c, 8b c, 0a c, 81 c, 12 c, b4 c, 47 c,
             ae c, f3 c, 4b c, d8 c, fb c, 5a c, 7b c, 82 c,
             9d c, 3e c, 86 c, 23 c, 71 c, d2 c, cf c, e5 c,
d# 24 buffer: result			\ 0011.2233 4455.6677 8899.aabb ccdd.eeff

kek crypt d# 16 result aes-unwrap u.	\ -1 is ok
result d# 16 dump

[then]
