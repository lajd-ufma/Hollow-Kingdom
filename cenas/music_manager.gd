extends Node


func tocar_musica01():
	$Level1.play()
	$Level2.stop()
	$Level3.stop()
	$Final.stop()
func tocar_musica02():
	$Level1.stop()
	$Level2.play()
	$Level3.stop()
	$Final.stop()
func tocar_musica03():
	$Level1.stop()
	$Level2.stop()
	$Level3.play()
	$Final.stop()
func final():
	$Level1.stop()
	$Level2.stop()
	$Level3.stop()
	$Final.play()
