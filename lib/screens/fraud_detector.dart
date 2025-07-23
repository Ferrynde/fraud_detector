import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DocumentFraudDetector extends StatefulWidget {
  @override
  _DocumentFraudDetectorState createState() => _DocumentFraudDetectorState();
}

class _DocumentFraudDetectorState extends State<DocumentFraudDetector> {
  Interpreter? _interpreter;
  File? _selectedImage;
  String _result = '';
  double _confidence = 0.0;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // Charger le modèle TensorFlow Lite
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('fraud_detection_model.tflite');
      print('Modèle chargé avec succès');
    } catch (e) {
      print('Erreur lors du chargement du modèle: $e');
    }
  }

  // Préprocessing de l'image
  Float32List _preprocessImage(File imageFile) {
    // Lire l'image
    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) throw Exception('Impossible de décoder l\'image');

    // Redimensionner à 128x128 (comme votre modèle)
    img.Image resizedImage = img.copyResize(image, width: 128, height: 128);

    // Convertir en Float32List et normaliser (0-1)
    Float32List inputBuffer = Float32List(128 * 128 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        int pixel = resizedImage.getPixel(x, y);
        inputBuffer[pixelIndex++] = img.getRed(pixel) / 255.0;
        inputBuffer[pixelIndex++] = img.getGreen(pixel) / 255.0;
        inputBuffer[pixelIndex++] = img.getBlue(pixel) / 255.0;
      }
    }

    return inputBuffer;
  }

  // Faire la prédiction
  Future<void> _predictImage(File imageFile) async {
    if (_interpreter == null) {
      setState(() {
        _result = 'Modèle non chargé';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Préprocessing
      Float32List input = _preprocessImage(imageFile);
      
      // Préparer le tensor d'entrée [1, 128, 128, 3]
      var inputTensor = input.reshape([1, 128, 128, 3]);
      
      // Préparer le tensor de sortie [1, 1]
      var outputTensor = Float32List(1).reshape([1, 1]);

      // Exécuter l'inférence
      _interpreter!.run(inputTensor, outputTensor);

      // Interpréter les résultats
      double prediction = outputTensor[0][0];
      
      if prediction < 0.5) {
        _result = 'AUTHENTIQUE';
        _confidence = (1 - prediction) * 100;
      } else {
        _result = 'FALSIFIÉ';
        _confidence = prediction * 100;
      }

    } catch (e) {
      _result = 'Erreur de prédiction: $e';
      _confidence = 0.0;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sélectionner une image depuis la galerie
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = '';
        _confidence = 0.0;
      });
      await _predictImage(_selectedImage!);
    }
  }

  // Prendre une photo avec la caméra
  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = '';
        _confidence = 0.0;
      });
      await _predictImage(_selectedImage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détecteur de Faux Documents'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone d'affichage de l'image
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sélectionnez ou prenez une photo\nd\'un document à analyser',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            SizedBox(height: 24),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Prendre Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 32),
            
            // Zone de résultats
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyse en cours...'),
                  ],
                ),
              )
            else if (_result.isNotEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _result == 'AUTHENTIQUE' 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _result == 'AUTHENTIQUE' 
                        ? Colors.green 
                        : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _result == 'AUTHENTIQUE' 
                          ? Icons.verified 
                          : Icons.warning,
                      size: 48,
                      color: _result == 'AUTHENTIQUE' 
                          ? Colors.green 
                          : Colors.red,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _result == 'AUTHENTIQUE' 
                            ? Colors.green[700] 
                            : Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Confiance: ${_confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _confidence / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _result == 'AUTHENTIQUE' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}

pizhdiozeqndcfo