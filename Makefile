template-preview-app:
	rm -rf .build/preview-app
	helm template test-preview-app charts/preview-app --output-dir=.build --set image=my-preview-app-image --set host=preview-app.example.com -f tests/preview-app/values.yaml --debug

template-stable-app:
	rm -rf .build/stable-app
	helm template test-stable-app charts/stable-app --output-dir=.build --set image=my-stable-app-image --set host=stable-app.example.com -f tests/preview-app/values.yaml --debug

template-app:
	rm -rf .build/app
	helm template test-app charts/app --output-dir=.build -f tests/app/values-full.yaml --debug

template-app-minimal:
	rm -rf .build/app
	helm template test-app-minimal charts/app --output-dir=.build -f tests/app/values-minimal.yaml --debug

template-metabase:
	rm -rf .build/metabase
	helm template test-metabase charts/metabase --output-dir=.build --debug

template-adminer:
	rm -rf .build/adminer
	helm template test-adminer charts/adminer --output-dir=.build -f tests/adminer/values.yaml --debug

template-n8n:
	rm -rf .build/n8n
	helm template test-n8n charts/n8n --output-dir=.build -f tests/n8n/values.yaml --debug

template-n8n-minimal:
	rm -rf .build/n8n
	helm template test-n8n-minimal charts/n8n --output-dir=.build -f tests/n8n/values-minimal.yaml --debug

template-rbac:
	rm -rf .build/rbac
	helm template test-user charts/rbac --output-dir=.build -f tests/rbac/values.yaml --debug

template-k8s-pwa-dashboard:
	rm -rf .build/k8s-pwa-dashboard
	helm template test-k8s-pwa-dashboard charts/k8s-pwa-dashboard --output-dir=.build -f tests/k8s-pwa-dashboard/values.yaml --debug

helm-template:
	make template-preview-app
	make template-stable-app
	make template-app
	make template-metabase
	make template-adminer
	make template-n8n
	make template-rbac
	make template-k8s-pwa-dashboard

helm-lint:
	helm lint charts/preview-app
	helm lint charts/stable-app
	helm lint charts/app
	helm lint charts/metabase
	helm lint charts/adminer
	helm lint charts/n8n
	helm lint charts/rbac
	helm lint charts/k8s-pwa-dashboard

clean:
	rm -rf .build
