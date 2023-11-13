test-preview-app:
	rm -rf .build/preview-app
	helm template test-preview-app charts/preview-app --output-dir=.build --set image=my-preview-app-image --set host=preview-app.example.com --debug

test-stable-app:
	rm -rf .build/stable-app
	helm template test-stable-app charts/stable-app --output-dir=.build --set image=my-stable-app-image --set host=stable-app.example.com --debug

test:
	make test-preview-app
	make test-stable-app

clean:
	rm -rf .build
