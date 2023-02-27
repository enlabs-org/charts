test-preview-app:
	rm -rf .build/preview-app
	helm template test-preview-app charts/preview-app --output-dir=.build --set image=my-preview-app-image --set host=preview-app.example.com --debug

clean:
	rm -rf .build
