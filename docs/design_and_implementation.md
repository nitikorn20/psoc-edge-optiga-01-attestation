[Click here](../README.md) to view the README.

## Design and implementation

The design of this application is minimalistic to get started with code examples on PSOC&trade; Edge MCU devices. All PSOC&trade; Edge E84 MCU applications have a dual-CPU three-project structure to develop code for the CM33 and CM55 cores. The CM33 core has two separate projects for the secure processing environment (SPE) and non-secure processing environment (NSPE).

This code example demonstrates how to use TrustedFirmware-M (TF-M) with Infineon's PSOC&trade; Edge MCU to generate an initial attestation token, which is used to prove the authenticity of a device. TF-M implements the SPE for Armv8-M and Armv8.1-M architectures (e.g., the Cortex&reg;-M33, Cortex&reg;-M23, Cortex&reg;-M55, and Cortex&reg;-M85 processors) and dual-core platforms. It is platform security architecture reference implementation aligning with PSA-certified guidelines, enabling chips, real-time operating systems, and devices to become PSA-certified. For more details, see the [TrustedFirmware-M Documentation](https://tf-m-user-guide.trustedfirmware.org/).

The extended boot launches the Edge Protect Bootloader (EPB) from the RRAM. The EPB authenticates the CM33 secure, CM33 non-secure, and CM55 projects, which are placed in the external flash and launches the CM33 secure application from the external Flash. The CM33 secure project contains TF-M. The Edge Protect Bootloader passes the boot measurements to TF-M for the initial attestation service.

The CM33 project contains TF-M, which creates an isolated space between the M33 secure and M33 non-secure images. TF-M offers initial attestation service which can be used by the non-secure application. The service is placed in an isolated TF-M partition. TF-M is available in source code format as a library in the *mtb_shared* directory. The CM33 secure application does not have any source files instead includes this TF-M library for building TF-M.

During the boot sequence, the TF-M's secure partition manager (SPM) forms the SPE using protection units and initializes all the TF-M partitions.  After initializing the partitions, TF-M launches the M33 NSPE project from the external flash, which enables M55 and initializes the M33 NSPE <-> M55 NSPE interface using the secure request framework (SRF). The M33 NSPE project requests TF-M service for attestation token. The attestation services needs a challenge as an input for token generation, typically this is a random number of 32,48, or 64 bytes. 

In the code example, M33 NSPE uses the TF-M Crypto service to generate a random number of 32 bytes. The generated random number is passed as an input to initial attestation service and the service returns the attestation token. The attestation token is stored in shared memory in SRAM1. In this example, M55 is not used, so it is put into Deep Sleep.

The code example is shipped with the extract_iat_iak_pkey.sh shell script, which can be found in *<WorkspacePath\>\\\<Application Name>\scripts* directory. The script performs the following tasks:

- Extracts the attestation token from SRAM1 shared memory and stores it in a CBOR file
- Extracts the alias certificate from the device
- Extracts the IAK public key from the alias certificate and stores it in a PEM file

All the extracted assets are stored in <WorkspacePath>\<Application Name> directory. To verify the authenticity of the device, the attestation token is shared to a verification entity, for example, cloud service. The entity uses the IAK public key to verify the signature and claims of the attestation token. Here, the iat-verifier from TF-M tools, a Python-based tool, is used to verify the signature and structure of the token locally. The extracted IAK public key and the attestation token should be passed to the *check_iat* script to verify the token.  

> **Note:** The *check_iat* script does not verify individual claims – it only verifies the token structure and signature. Typically, all the received list of claims are verified against a database of known measurements for each component by the verification service.

For more information about the claims, see **Getting started with Trusted Firmware-M (TF-M) on PSOC&trade; Edge** and [IHI0085-PSA_Certified_Attestation_API](https://arm-software.github.io/psa-api/attestation/).

You can check the content of the token using the decompile_token script of the iat-verifier tool. Use Modus Shell and execute the following command from the *<WorkspacePath\>\tf-m-tools\iat-verifier* directory.

```
python scripts/decompile_token -t PSA-2.0.0-token Attestation_token.cbor
```

A project folder consists of various subfolders, each denoting a specific aspect of the project. The three project folders are as follows:

**Table 1. Application projects**

Project | Description
--------|------------------------
proj_cm33_s | TF-M (SPE)
proj_cm33_ns | M33 NSPE
proj_cm55 | M55 NSPE 

<br>