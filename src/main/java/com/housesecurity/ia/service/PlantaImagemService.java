package com.housesecurity.ia.service;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

/**
 * Transforma PNG, JPG ou PDF em imagens JPEG (em Base64) prontas para enviar à IA.
 */
@Service
public class PlantaImagemService {

    private static final int LADO_MAXIMO_PIXELS = 1600; // reduz imagens gigantes
    private static final int MAXIMO_PAGINAS_PDF = 3;    // limite do modelo: 3 imagens
    private static final int DPI_DO_PDF = 100;          // qualidade ao converter PDF em imagem

    public static boolean formatoSuportado(Path arquivo) {
        String nome = arquivo.getFileName().toString().toLowerCase();
        return nome.endsWith(".png") || nome.endsWith(".jpg")
                || nome.endsWith(".jpeg") || nome.endsWith(".pdf");
    }

    /**
     * Devolve uma lista de imagens em Base64 (uma por página, se for PDF).
     */
    public List<String> converterParaBase64(Path arquivo) throws IOException {
        String nome = arquivo.getFileName().toString().toLowerCase();
        List<BufferedImage> imagens = new ArrayList<>();

        if (nome.endsWith(".pdf")) {
            try (PDDocument documento = Loader.loadPDF(arquivo.toFile())) {
                int paginas = Math.min(documento.getNumberOfPages(), MAXIMO_PAGINAS_PDF);
                PDFRenderer renderizador = new PDFRenderer(documento);
                for (int i = 0; i < paginas; i++) {
                    imagens.add(renderizador.renderImageWithDPI(i, DPI_DO_PDF, ImageType.RGB));
                }
            }
        } else if (nome.endsWith(".png") || nome.endsWith(".jpg") || nome.endsWith(".jpeg")) {
            BufferedImage imagem = ImageIO.read(arquivo.toFile());
            if (imagem == null) {
                throw new IOException("Não consegui abrir a imagem: " + arquivo.getFileName());
            }
            imagens.add(imagem);
        } else {
            throw new IOException("Formato não suportado. Use PNG, JPG ou PDF.");
        }

        if (imagens.isEmpty()) {
            throw new IOException("O arquivo não tem nenhuma página/imagem para analisar.");
        }

        List<String> resultado = new ArrayList<>();
        for (BufferedImage imagem : imagens) {
            resultado.add(paraJpegBase64(reduzirEPintarFundoBranco(imagem)));
        }
        return resultado;
    }

    /**
     * Reduz a imagem se for muito grande e troca fundo transparente por branco.
     */
    private BufferedImage reduzirEPintarFundoBranco(BufferedImage original) {
        int largura = original.getWidth();
        int altura = original.getHeight();

        double escala = Math.min(1.0, (double) LADO_MAXIMO_PIXELS / Math.max(largura, altura));
        int novaLargura = Math.max(1, (int) Math.round(largura * escala));
        int novaAltura = Math.max(1, (int) Math.round(altura * escala));

        BufferedImage saida = new BufferedImage(novaLargura, novaAltura, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = saida.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, novaLargura, novaAltura);
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g.drawImage(original, 0, 0, novaLargura, novaAltura, null);
        g.dispose();
        return saida;
    }

    private String paraJpegBase64(BufferedImage imagem) throws IOException {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        ImageIO.write(imagem, "jpg", bytes);
        return Base64.getEncoder().encodeToString(bytes.toByteArray());
    }
}