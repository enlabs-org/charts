template-preview-app:
	rm -rf .build/preview-app
	helm template test-preview-app charts/preview-app --output-dir=.build --set image=my-preview-app-image --set host=preview-app.example.com --debug

template-stable-app:
	rm -rf .build/stable-app
	helm template test-stable-app charts/stable-app --output-dir=.build --set image=my-stable-app-image --set host=stable-app.example.com --debug

template-metabase:
	rm -rf .build/metabase
	helm template test-metabase charts/metabase --output-dir=.build --debug

helm-template:
	make template-preview-app
	make template-stable-app
	make template-metabase

helm-lint:
	helm lint charts/preview-app
	helm lint charts/stable-app
	helm lint charts/metabase

clean:
	rm -rf .build
