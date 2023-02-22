test-preview-app:
	rm -rf .build/preview-app
	helm template test-preview-app preview-app --output-dir=.build --set image=my-preview-app-image --set host=preview-app.example.com

clean:
	rm -rf .build
