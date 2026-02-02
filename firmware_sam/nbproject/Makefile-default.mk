#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
ifeq "${IGNORE_LOCAL}" "TRUE"
# do not include local makefile. User is passing all local related variables already
else
include Makefile
# Include makefile containing local settings
ifeq "$(wildcard nbproject/Makefile-local-default.mk)" "nbproject/Makefile-local-default.mk"
include nbproject/Makefile-local-default.mk
endif
endif

# Environment
MKDIR=mkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=default
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
OUTPUT_SUFFIX=elf
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
endif

ifeq ($(COMPARE_BUILD), true)
COMPARISON_BUILD=
else
COMPARISON_BUILD=
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Source Files Quoted if spaced
SOURCEFILES_QUOTED_IF_SPACED=src/startup.c src/system.c src/sercom_spi.c src/sercom_uart.c src/libc_stub.c src/bmi088.c src/attitude.c src/control.c src/rc_input.c src/motion_script.c src/odometry.c src/tmc2209.c src/main.c

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/src/startup.o ${OBJECTDIR}/src/system.o ${OBJECTDIR}/src/sercom_spi.o ${OBJECTDIR}/src/sercom_uart.o ${OBJECTDIR}/src/libc_stub.o ${OBJECTDIR}/src/bmi088.o ${OBJECTDIR}/src/attitude.o ${OBJECTDIR}/src/control.o ${OBJECTDIR}/src/rc_input.o ${OBJECTDIR}/src/motion_script.o ${OBJECTDIR}/src/odometry.o ${OBJECTDIR}/src/tmc2209.o ${OBJECTDIR}/src/main.o
POSSIBLE_DEPFILES=${OBJECTDIR}/src/startup.o.d ${OBJECTDIR}/src/system.o.d ${OBJECTDIR}/src/sercom_spi.o.d ${OBJECTDIR}/src/sercom_uart.o.d ${OBJECTDIR}/src/libc_stub.o.d ${OBJECTDIR}/src/bmi088.o.d ${OBJECTDIR}/src/attitude.o.d ${OBJECTDIR}/src/control.o.d ${OBJECTDIR}/src/rc_input.o.d ${OBJECTDIR}/src/motion_script.o.d ${OBJECTDIR}/src/odometry.o.d ${OBJECTDIR}/src/tmc2209.o.d ${OBJECTDIR}/src/main.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/src/startup.o ${OBJECTDIR}/src/system.o ${OBJECTDIR}/src/sercom_spi.o ${OBJECTDIR}/src/sercom_uart.o ${OBJECTDIR}/src/libc_stub.o ${OBJECTDIR}/src/bmi088.o ${OBJECTDIR}/src/attitude.o ${OBJECTDIR}/src/control.o ${OBJECTDIR}/src/rc_input.o ${OBJECTDIR}/src/motion_script.o ${OBJECTDIR}/src/odometry.o ${OBJECTDIR}/src/tmc2209.o ${OBJECTDIR}/src/main.o

# Source Files
SOURCEFILES=src/startup.c src/system.c src/sercom_spi.c src/sercom_uart.c src/libc_stub.c src/bmi088.c src/attitude.c src/control.c src/rc_input.c src/motion_script.c src/odometry.c src/tmc2209.c src/main.c

# Pack Options 
PACK_COMMON_OPTIONS=-I "${CMSIS_DIR}/CMSIS/Core/Include"



CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps

.build-conf:  ${BUILD_SUBPROJECTS}
ifneq ($(INFORMATION_MESSAGE), )
	@echo $(INFORMATION_MESSAGE)
endif
	${MAKE}  -f nbproject/Makefile-default.mk ${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${OUTPUT_SUFFIX}

MP_PROCESSOR_OPTION=ATSAME51J20A
MP_LINKER_FILE_OPTION=
# ------------------------------------------------------------------------------------
# Rules for buildStep: assemble
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: assembleWithPreprocess
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: compile
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/src/startup.o: src/startup.c  .generated_files/flags/default/ffa31889ff5476fc42279ce0c97cc1e95e066e73 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/startup.o.d 
	@${RM} ${OBJECTDIR}/src/startup.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/startup.o.d" -o ${OBJECTDIR}/src/startup.o src/startup.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/system.o: src/system.c  .generated_files/flags/default/8ae68dedaaeaacb2801f55fe57a82d4e58fe7446 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/system.o.d 
	@${RM} ${OBJECTDIR}/src/system.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/system.o.d" -o ${OBJECTDIR}/src/system.o src/system.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/sercom_spi.o: src/sercom_spi.c  .generated_files/flags/default/8eaa995c950e3079366251b7d8524151f9aab6f0 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/sercom_spi.o.d 
	@${RM} ${OBJECTDIR}/src/sercom_spi.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/sercom_spi.o.d" -o ${OBJECTDIR}/src/sercom_spi.o src/sercom_spi.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/sercom_uart.o: src/sercom_uart.c  .generated_files/flags/default/b19d9b84e46a2c7f73e64b27f83693e7129e37d2 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/sercom_uart.o.d 
	@${RM} ${OBJECTDIR}/src/sercom_uart.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/sercom_uart.o.d" -o ${OBJECTDIR}/src/sercom_uart.o src/sercom_uart.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/libc_stub.o: src/libc_stub.c  .generated_files/flags/default/d3f5569cb64b0459cffb350b9f33ea8955d6f876 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/libc_stub.o.d 
	@${RM} ${OBJECTDIR}/src/libc_stub.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/libc_stub.o.d" -o ${OBJECTDIR}/src/libc_stub.o src/libc_stub.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/bmi088.o: src/bmi088.c  .generated_files/flags/default/7b7c9839d35e8b74a085eaf78047735d4ec37bc0 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/bmi088.o.d 
	@${RM} ${OBJECTDIR}/src/bmi088.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/bmi088.o.d" -o ${OBJECTDIR}/src/bmi088.o src/bmi088.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/attitude.o: src/attitude.c  .generated_files/flags/default/f76ead94b777da0667ccc391e842d635a042e291 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/attitude.o.d 
	@${RM} ${OBJECTDIR}/src/attitude.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/attitude.o.d" -o ${OBJECTDIR}/src/attitude.o src/attitude.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/control.o: src/control.c  .generated_files/flags/default/1b93e563c7b033450f5cbc2cd369b8710fd1f1a3 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/control.o.d 
	@${RM} ${OBJECTDIR}/src/control.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/control.o.d" -o ${OBJECTDIR}/src/control.o src/control.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/rc_input.o: src/rc_input.c  .generated_files/flags/default/3aeab0d237bd2d7968bd6478412cb8df1626d7e4 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/rc_input.o.d 
	@${RM} ${OBJECTDIR}/src/rc_input.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/rc_input.o.d" -o ${OBJECTDIR}/src/rc_input.o src/rc_input.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/motion_script.o: src/motion_script.c  .generated_files/flags/default/e1c7620ce95af029feec437adbb35d63be674ad5 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/motion_script.o.d 
	@${RM} ${OBJECTDIR}/src/motion_script.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/motion_script.o.d" -o ${OBJECTDIR}/src/motion_script.o src/motion_script.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/odometry.o: src/odometry.c  .generated_files/flags/default/54d10960ae331c2af8e5363628c684022cbfda27 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/odometry.o.d 
	@${RM} ${OBJECTDIR}/src/odometry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/odometry.o.d" -o ${OBJECTDIR}/src/odometry.o src/odometry.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/tmc2209.o: src/tmc2209.c  .generated_files/flags/default/223b536dd199f9e924a10fd87fea50dee4a59b55 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/tmc2209.o.d 
	@${RM} ${OBJECTDIR}/src/tmc2209.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/tmc2209.o.d" -o ${OBJECTDIR}/src/tmc2209.o src/tmc2209.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/main.o: src/main.c  .generated_files/flags/default/d5469a95964f95fc5b4162d27f9ddc6b560b0cfb .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/main.o.d 
	@${RM} ${OBJECTDIR}/src/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE) -g -D__DEBUG   -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/main.o.d" -o ${OBJECTDIR}/src/main.o src/main.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
else
${OBJECTDIR}/src/startup.o: src/startup.c  .generated_files/flags/default/7e5f4ff879784dc889f34da3a56642e393d5348f .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/startup.o.d 
	@${RM} ${OBJECTDIR}/src/startup.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/startup.o.d" -o ${OBJECTDIR}/src/startup.o src/startup.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/system.o: src/system.c  .generated_files/flags/default/aa0262e751d7c66c24a9636d725daf7e0a4d3fc4 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/system.o.d 
	@${RM} ${OBJECTDIR}/src/system.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/system.o.d" -o ${OBJECTDIR}/src/system.o src/system.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/sercom_spi.o: src/sercom_spi.c  .generated_files/flags/default/7473511d49b5a915e80be855e7cc612349082ae0 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/sercom_spi.o.d 
	@${RM} ${OBJECTDIR}/src/sercom_spi.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/sercom_spi.o.d" -o ${OBJECTDIR}/src/sercom_spi.o src/sercom_spi.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/sercom_uart.o: src/sercom_uart.c  .generated_files/flags/default/acfa02736f7f363f42ad72e0fc99320a24fd8154 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/sercom_uart.o.d 
	@${RM} ${OBJECTDIR}/src/sercom_uart.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/sercom_uart.o.d" -o ${OBJECTDIR}/src/sercom_uart.o src/sercom_uart.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/libc_stub.o: src/libc_stub.c  .generated_files/flags/default/f62cb7b6c44d559812953ad2208ea0c3e9b3058b .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/libc_stub.o.d 
	@${RM} ${OBJECTDIR}/src/libc_stub.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/libc_stub.o.d" -o ${OBJECTDIR}/src/libc_stub.o src/libc_stub.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/bmi088.o: src/bmi088.c  .generated_files/flags/default/a36204488b1a6e3c0fa1b76c9843015e6d0a1a48 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/bmi088.o.d 
	@${RM} ${OBJECTDIR}/src/bmi088.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/bmi088.o.d" -o ${OBJECTDIR}/src/bmi088.o src/bmi088.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/attitude.o: src/attitude.c  .generated_files/flags/default/34e357a2aa9d0415cbe2da98bfcc0d508ff4993 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/attitude.o.d 
	@${RM} ${OBJECTDIR}/src/attitude.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/attitude.o.d" -o ${OBJECTDIR}/src/attitude.o src/attitude.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/control.o: src/control.c  .generated_files/flags/default/dcc9186c16984e98ec8d6ecd2b4b0334fc5debcd .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/control.o.d 
	@${RM} ${OBJECTDIR}/src/control.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/control.o.d" -o ${OBJECTDIR}/src/control.o src/control.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/rc_input.o: src/rc_input.c  .generated_files/flags/default/7dde15c231f3da5e0bf82089c2625a24cbb58e84 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/rc_input.o.d 
	@${RM} ${OBJECTDIR}/src/rc_input.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/rc_input.o.d" -o ${OBJECTDIR}/src/rc_input.o src/rc_input.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/motion_script.o: src/motion_script.c  .generated_files/flags/default/230bd5891cf3aa852467e1312a58d6f3e97e6f34 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/motion_script.o.d 
	@${RM} ${OBJECTDIR}/src/motion_script.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/motion_script.o.d" -o ${OBJECTDIR}/src/motion_script.o src/motion_script.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/odometry.o: src/odometry.c  .generated_files/flags/default/839facc6e58b110d337619d3073eaf081d625103 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/odometry.o.d 
	@${RM} ${OBJECTDIR}/src/odometry.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/odometry.o.d" -o ${OBJECTDIR}/src/odometry.o src/odometry.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/tmc2209.o: src/tmc2209.c  .generated_files/flags/default/1b5c3ea7288429bf67ce596b494aae525d10e762 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/tmc2209.o.d 
	@${RM} ${OBJECTDIR}/src/tmc2209.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/tmc2209.o.d" -o ${OBJECTDIR}/src/tmc2209.o src/tmc2209.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
${OBJECTDIR}/src/main.o: src/main.c  .generated_files/flags/default/416c90edfa5d9ceb2751ea134328a3a302ca8e20 .generated_files/flags/default/da39a3ee5e6b4b0d3255bfef95601890afd80709
	@${MKDIR} "${OBJECTDIR}/src" 
	@${RM} ${OBJECTDIR}/src/main.o.d 
	@${RM} ${OBJECTDIR}/src/main.o 
	${MP_CC}  $(MP_EXTRA_CC_PRE)  -g -x c -c -mprocessor=$(MP_PROCESSOR_OPTION)  -O0 -MP -MMD -MF "${OBJECTDIR}/src/main.o.d" -o ${OBJECTDIR}/src/main.o src/main.c    -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)   ${PACK_COMMON_OPTIONS} 
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: compileCPP
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
else
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: link
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    
	@${MKDIR} ${DISTDIR} 
	${MP_CC} $(MP_EXTRA_LD_PRE) -g   -mprocessor=$(MP_PROCESSOR_OPTION)  -o ${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${OUTPUT_SUFFIX} ${OBJECTFILES_QUOTED_IF_SPACED}          -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)  -Wl,--defsym=__MPLAB_BUILD=1$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map" 
	
else
${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   
	@${MKDIR} ${DISTDIR} 
	${MP_CC} $(MP_EXTRA_LD_PRE)  -mprocessor=$(MP_PROCESSOR_OPTION)  -o ${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} ${OBJECTFILES_QUOTED_IF_SPACED}          -DXPRJ_default=$(CND_CONF)    $(COMPARISON_BUILD)  -Wl,--defsym=__MPLAB_BUILD=1$(MP_EXTRA_LD_POST)$(MP_LINKER_FILE_OPTION),-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map" 
	${MP_CC_DIR}/xc32-bin2hex ${DISTDIR}/firmware_sam.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} 
endif


# Subprojects
.build-subprojects:


# Subprojects
.clean-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${OBJECTDIR}
	${RM} -r ${DISTDIR}
