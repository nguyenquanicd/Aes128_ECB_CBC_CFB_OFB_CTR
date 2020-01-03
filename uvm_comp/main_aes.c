#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "aes.h"

uint8_t* Xcrypt_ecb(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
uint8_t* Xcrypt_cbc(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
uint8_t* Xcrypt_ctr(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
uint8_t* Xcrypt_ofb(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
uint8_t* Xcrypt_cfb(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv, uint8_t sbit)

uint8_t* main(uint8_t mode, uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* iv, uint8_t* out, uint8_t sbit)
{
    switch (mode) {
		case 0:
		    Xcrypt_ecb(xcrypt,key,in,out,iv); break;
		case 1:
            Xcrypt_cbc(xcrypt,key,in,out,iv); break;
        case 2:
            Xcrypt_ctr(xcrypt,key,in,out,iv); break;
		case 3:
            Xcrypt_ofb(xcrypt,key,in,out,iv); break;
        case 4:
            Xcrypt_cfb(xcrypt,key,in,out,iv,sbit); break;
		default:
		    printf("Error: Cipher mode is not correct. Please check again...!");
	}
	return out;
}

uint8_t* Xcrypt_ecb(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
{
	printf("AES-128; ECB mode\n");
	if(xcrypt == 0) {
		printf("ECB encrypt\n");
        struct AES_ctx ctx;
        AES_init_ctx(&ctx,key);
        AES_ECB_encrypt(&ctx,in);
        out = in;
	}
    else if(xcrypt == 1) {
		printf("ECB decrypt\n");
        struct AES_ctx ctx;
        AES_init_ctx(&ctx,key);
        AES_ECB_decrypt(&ctx,in);
        out = in;
	}
	else {
		printf("Cipher mode wrong: Please choose 0/1 for encrypt/decrypt...\n")
		return NULL;
	}
	return out;
}

uint8_t* Xcrypt_cbc(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
{
	printf("AES-128; CBC mode\n");
	if(xcrypt == 0) {
		printf("CBC encrypt\n");
        struct AES_ctx ctx;
        AES_init_ctx_iv(&ctx,key, iv);
        AES_CBC_encrypt_buffer(&ctx,in,64);
        out = in;
	}
    else if(xcrypt == 1) {
		printf("CBC decrypt\n");
        struct AES_ctx ctx;
        AES_init_ctx_iv(&ctx,key,iv);
        AES_CBC_decrypt_buffer(&ctx,in,64);
        out = in;
	}
	else {
		printf("Cipher mode wrong: Please choose 0/1 for encrypt/decrypt...\n")
		return NULL;
	}
	return out;
}


uint8_t* Xcrypt_ctr(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
{
	printf("AES-128; CTR mode\n");
	if(xcrypt == 0) {
		printf("CTR encrypt\n");
	}
    else if(xcrypt == 1) {
		printf("CTR decrypt\n");
	}
	else {
		printf("Cipher mode wrong: Please choose 0/1 for encrypt/decrypt...\n")
		return NULL;
	}

    struct AES_ctx ctx;
    AES_init_ctx_iv(&ctx,key,iv);
    AES_CTR_xcrypt_buffer(&ctx,in,64);
    out = in;
     	
	
	return out;
}

uint8_t* Xcrypt_ofb(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv)
{
	printf("AES-128; OFB mode\n");
	if(xcrypt == 0) {
		printf("OFB encrypt\n");
	}
    else if(xcrypt == 1) {
		printf("OFB decrypt\n");
	}
	else {
		printf("Cipher mode wrong: Please choose 0/1 for encrypt/decrypt...\n")
		return NULL;
	}

    struct AES_ctx ctx;
    AES_init_ctx_iv(&ctx,key,iv);
    AES_OFB_xcrypt_buffer(&ctx,in,64);
    out = in;
     	
	
	return out;
}		


uint8_t* Xcrypt_cfb(uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* out, uint8_t* iv, uint8_t sbit)
{
	printf("AES-128; CFB mode\n");
	if(xcrypt == 0) {
		printf("CFB encrypt\n");
	}
    else if(xcrypt == 1) {
		printf("CFB decrypt\n");
	}
	else {
		printf("Cipher mode wrong: Please choose 0/1 for encrypt/decrypt...\n")
		return NULL;
	}

    struct AES_ctx ctx;
    AES_init_ctx_iv(&ctx,key,iv);
    AES_CFB_xcrypt_buffer(&ctx,in,64, sbit);
    out = in;
     	
	
	return out;
}	