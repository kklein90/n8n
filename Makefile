
encrypt:
	cd infra/kubernetes/overlays/home/secrets/confidential && sops -e -pgp ${SOPSKEY} n8n.env > n8n.enc.env
decrypt: 
	cd infra/kubernetes/overlays/home/secrets/confidential && sops - -pgp ${SOPSKEY} n8n.enc.env > n8n.env

.PHONY: encrypt decrypt