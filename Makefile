SHELL:=/bin/bash

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

param: ## Setting deploy configuration
	@TMP_PROJECT=$(shell gcloud config list --format 'value(core.project)'); \
	read -e -p "Enter Your Project Name: " -i $${TMP_PROJECT} PROJECT_ID; \
	gcloud config set project $${PROJECT_ID}; \
	read -e -p "Enter Desired Cloud Run Region: " -i 'europe-west1' CLOUD_RUN_REGION; \
	gcloud config set run/region $${CLOUD_RUN_REGION}; \
	read -e -p "Enter Desired Cloud Run Platform: " -i 'managed' CLOUD_RUN_PLATFORM; \
	gcloud config set run/platform $${CLOUD_RUN_PLATFORM};

init: ## Activation of API, creation of service account with publisher role
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	gcloud iam service-accounts create gcr-xia-pusher-01 \
		--display-name "Cloud Run Push Agent"; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:gcr-xia-pusher-01@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:gcr-xia-pusher-01@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:gcr-xia-pusher-01@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/storage.objectAdmin; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:gcr-xia-pusher-01@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker; \

build: ## Build and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/xia-pusher-01;

deploy: ## Deploy Cloud Run Image by using the last built image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLOUD_RUN_REGION=$(shell gcloud config list --format 'value(run.region)'); \
	CLOUD_RUN_PLATFORM=$(shell gcloud config list --format 'value(run.platform)'); \
	gcloud run deploy xia-pusher-01 \
		--image gcr.io/$${PROJECT_ID}/xia-pusher-01 \
		--service-account gcr-xia-pusher-01@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform managed \
		--no-allow-unauthenticated;
