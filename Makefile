template-preview-app:
	rm -rf .build/preview-app
	helm template test-preview-app charts/preview-app --output-dir=.build --set image=my-preview-app-image --set host=preview-app.example.com -f tests/preview-app/values.yaml --debug

template-stable-app:
	rm -rf .build/stable-app
	helm template test-stable-app charts/stable-app --output-dir=.build --set image=my-stable-app-image --set host=stable-app.example.com --debug

template-metabase:
	rm -rf .build/metabase
	helm template test-metabase charts/metabase --output-dir=.build --debug

template-adminer:
	rm -rf .build/adminer
	helm template test-adminer charts/adminer --output-dir=.build -f tests/adminer/values.yaml --debug

template-n8n:
	rm -rf .build/n8n
	helm template test-n8n charts/n8n --output-dir=.build --debug

template-rbac:
	rm -rf .build/rbac
	helm template test-user charts/rbac --output-dir=.build -f tests/rbac/values.yaml --debug

helm-template:
	make template-preview-app
	make template-stable-app
	make template-metabase
	make template-adminer
	make template-rbac

helm-lint:
	helm lint charts/preview-app
	helm lint charts/stable-app
	helm lint charts/metabase
	helm lint charts/adminer
	helm lint charts/rbac

clean:
	rm -rf .build
